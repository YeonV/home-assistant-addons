#!/usr/bin/with-contenv bashio

# ==============================================================================
# Script constants
# ==============================================================================
# Home Assistant API URL (internal via supervisor)
HA_API_URL="http://supervisor/core/api"

# ==============================================================================
# Helper Functions
# ==============================================================================
# Function to publish service using avahi-publish
# Args: interface name type port ip [txt_key=txt_value...]
publish_service() {
    local interface="$1"
    local name="$2"
    local type="$3"
    local port="$4"
    local ip="$5"
    shift 5 # Remove first 5 args

    local txt_args=()
    for txt in "$@"; do
        txt_args+=("$(printf '%q' "$txt")") # Quote properly for shell command
    done

    # Using -R to remove conflicting services with the same name/type/domain
    # Using -a to add (or update if already present with same name?)
    bashio::log.debug "Publishing: Name='${name}', Type='${type}', Port=${port}, IP=${ip}, TXT='${txt_args[*]}' on Interface='${interface}'"
    if avahi-publish \
        --interface "$(printf '%q' "$interface")" \
        --subtype _home-assistant._sub."${type}" \
        -a \
        -R \
        "$(printf '%q' "$name")" \
        "$(printf '%q' "$type")" \
        "$port" \
        "ip=${ip}" \
        "${txt_args[@]}" >/dev/null 2>&1; then
        bashio::log.trace "Successfully published '${name}' (${ip})"
    else
        bashio::log.warning "Failed to publish '${name}' (${ip})"
    fi
}

# ==============================================================================
# Main Script Logic
# ==============================================================================
bashio::log.info "Starting mDNS Advertiser..."

# Validate SUPERVISOR_TOKEN
if [[ -z "${SUPERVISOR_TOKEN}" ]]; then
    bashio::log.fatal "Supervisor token not available. Is hassio_api=true set?"
    exit 1
fi

# Read configuration
IFACE=$(bashio::config 'interface')
UPDATE_INTERVAL=$(bashio::config 'update_interval')
LOG_LEVEL=$(bashio::config 'log_level')
bashio::log.level "${LOG_LEVEL}"

bashio::log.info "Advertising on interface: ${IFACE}"
bashio::log.info "Update interval: ${UPDATE_INTERVAL} seconds"

# Main loop
while true; do
    bashio::log.debug "Starting update cycle..."
    # ... (Fetch states_json and devices_json) ...
    # bashio::log.debug "Attempting to fetch devices from API: ${HA_API_URL}/devices"
    # devices_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET \
    #     -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
    #     -H "Content-Type: application/json" \
    #     "${HA_API_URL}/devices")
    # devices_status=$(echo "$devices_response" | grep HTTP_STATUS | cut -d':' -f2)
    # devices_json=$(echo "$devices_response" | sed '$d')
    # if [[ "$devices_status" -ne 200 ]] || ! echo "$devices_json" | jq -e . > /dev/null; then
    #     bashio::log.error "Failed to fetch or parse /api/devices (HTTP: ${devices_status}). Skipping cycle."
    #     sleep "${UPDATE_INTERVAL}"
    #     continue
    # fi
    # bashio::log.debug "Successfully fetched and parsed /api/devices."

    bashio::log.debug "Attempting to fetch states from API: ${HA_API_URL}/states"

    # Capture response body AND http status code
    http_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        -H "Content-Type: application/json" \
        "${HA_API_URL}/states")

    # Separate status code from body
    http_status=$(echo "$http_response" | grep HTTP_STATUS | cut -d':' -f2)
    states_json=$(echo "$http_response" | sed '$d') # Remove last line (status code)

    bashio::log.debug "Received HTTP Status: ${http_status}"
    # Log the first few characters of the response for inspection
    bashio::log.debug "Received Response Body (first 400 chars): $(echo "$states_json" | head -c 400)"

    # Check HTTP status code explicitly
    if [[ "$http_status" -ne 200 ]]; then
        bashio::log.error "API request failed with HTTP status: ${http_status}"
        bashio::log.error "Response Body: ${states_json}" # Log the full body on error
        sleep "${UPDATE_INTERVAL}"
        continue
    fi

    # Check if the body is empty (even if status is 200)
    if [[ -z "$states_json" ]]; then
        bashio::log.error "API request succeeded (HTTP 200) but returned empty body."
        sleep "${UPDATE_INTERVAL}"
        continue
    fi

    # Check if parsing the whole states_json is valid initially (Good practice)
    if ! echo "$states_json" | jq -e . > /dev/null; then
        bashio::log.error "Initial parsing of full states_json failed. This shouldn't happen if HTTP 200."
        # Log more if needed: bashio::log.debug "Full states_json was: ${states_json}"
        sleep "${UPDATE_INTERVAL}"
        continue
    fi
    bashio::log.debug "Initial parsing of full states_json successful."

    # Get configured services from options.json using jq
    num_services=$(bashio::config 'services | length')
    bashio::log.debug "Found ${num_services} service configurations."

    # Loop through each configured service rule (assuming one rule for WLED)
for i in $(seq 0 $((num_services - 1))); do
    # ... (Read config: name, filters, service_type, port, etc.) ...
    # ... (Ensure ip_source is 'state', ha_entity_pattern is 'sensor.*_ip', state filter is set) ...

    # ... (Construct jq filter for IP sensors - including state != 'unavailable') ...
    bashio::log.debug "Constructed IP Sensor jq filter: ${jq_filter}"

    # --- Filter IP Sensor States ---
    bashio::log.debug "Filtering IP sensor entities..."
    # Use map() for potentially cleaner processing if dealing with multiple sensors later
    filtered_ip_sensors_json=$(jq -c "[.[] | ${jq_filter}]" <<< "$states_json")
    filter_exit_code=$?
    # ... (Handle filter errors, check if result is empty array '[]') ...
    bashio::log.debug "Filtered IP sensors (first 500): $(echo "$filtered_ip_sensors_json" | head -c 500)"

    # --- Process each found IP Sensor ---
    echo "$filtered_ip_sensors_json" | jq -c '.[]' | while IFS= read -r single_ip_sensor_json; do
        bashio::log.info "[MARKER 3.1] Processing IP Sensor JSON: ${single_ip_sensor_json}"

        # Extract Sensor Info
        sensor_entity_id=$(jq -r '.entity_id' <<< "$single_ip_sensor_json")
        entity_ip=$(jq -r '.state' <<< "$single_ip_sensor_json") # IP from state
        sensor_friendly_name=$(jq -r '.attributes.friendly_name // $sensor_entity_id' <<< "$single_ip_sensor_json") # Sensor's own name as fallback

        if [[ -z "$sensor_entity_id" ]] || [[ -z "$entity_ip" ]]; then
            bashio::log.warning "Could not extract entity_id or IP from sensor object. Skipping."
            continue
        fi
        bashio::log.debug "Found IP Sensor: ${sensor_entity_id} with IP: ${entity_ip}"

        # # --- Find Device ID using Sensor Entity ID ---
        # bashio::log.debug "Searching for Device ID for sensor ${sensor_entity_id}..."
        # # JQ query to find the device containing this sensor entity_id
        # device_id=$(jq -r --arg sensor_id "$sensor_entity_id" \
        #     '.[] | select(.entities[]?.entity_id == $sensor_id) | .id | first' \
        #     <<< "$devices_json") # Use 'first' in case of weird duplicates

        # if [[ -z "$device_id" ]] || [[ "$device_id" == "null" ]]; then
        #     bashio::log.warning "Could not find Device ID for sensor ${sensor_entity_id}. Using sensor name as fallback."
        #     target_friendly_name="$sensor_friendly_name" # Fallback name
        # else
        #     bashio::log.debug "Found Device ID: ${device_id}"

        #     # --- Find Light Entity ID using Device ID ---
        #     bashio::log.debug "Searching for light entity for Device ID ${device_id}..."
        #     # JQ query to find the first entity starting with 'light.' within that device
        #     light_entity_id=$(jq -r --arg dev_id "$device_id" \
        #         '.[] | select(.id == $dev_id) | .entities[]? | select(.entity_id? | startswith("light.")) | .entity_id | first' \
        #         <<< "$devices_json")

        #     if [[ -z "$light_entity_id" ]] || [[ "$light_entity_id" == "null" ]]; then
        #         bashio::log.warning "Could not find light entity for Device ID ${device_id}. Using sensor name as fallback."
        #         target_friendly_name="$sensor_friendly_name" # Fallback name
        #     else
        #         bashio::log.debug "Found Light Entity ID: ${light_entity_id}"

        #         # --- Get Light Entity's Friendly Name from States ---
        #         bashio::log.debug "Looking up state for light ${light_entity_id}..."
        #         # JQ query to find the state object for the light entity
        #         light_state_json=$(jq -c --arg light_id "$light_entity_id" \
        #             '.[] | select(.entity_id == $light_id)' \
        #             <<< "$states_json")

        #         if [[ -z "$light_state_json" ]] || [[ "$light_state_json" == "null" ]]; then
        #              bashio::log.warning "Could not find state for light entity ${light_entity_id}. Using sensor name as fallback."
        #              target_friendly_name="$sensor_friendly_name" # Fallback name
        #         else
        #             # Extract friendly name with fallback to entity_id
        #             target_friendly_name=$(jq -r '.attributes.friendly_name // .entity_id' <<< "$light_state_json")
        #             bashio::log.debug "Using friendly name from light entity: '${target_friendly_name}'"
        #         fi
        #     fi
        # fi

        # --- Publish using the determined name and IP ---
        bashio::log.info "Publishing mDNS for '${sensor_friendly_name}' -> ${entity_ip}"
        publish_service "${IFACE}" "${sensor_friendly_name}" "${service_type}" "${service_port}" "${entity_ip}"
        # bashio::log.info "Publishing mDNS for '${target_friendly_name}' -> ${entity_ip}"
        # publish_service "${IFACE}" "${target_friendly_name}" "${service_type}" "${service_port}" "${entity_ip}"

        done # End of processing entities for one service rule
        bashio::log.info "[MARKER 5] Finished STEP 3 processing loop."

        # --- ADD MARKER 6 ---
        bashio::log.info "[MARKER 6] Reached end of FOR loop iteration for index ${i}."

    done # End of looping through service rules

    # --- ADD MARKER 7 ---
    bashio::log.info "[MARKER 7] Exited FOR loop."
    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done # End while true