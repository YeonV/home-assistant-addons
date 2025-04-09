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
    bashio::log.debug "Received Response Body: $(echo "$states_json" | head -c 400)"

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

    # Loop through each configured service rule
    for i in $(seq 0 $((num_services - 1))); do
        # --- LOG ENTRY INTO LOOP ITERATION ---
        bashio::log.info "--- Processing Service Index: ${i} ---"
        # --- END LOG ENTRY ---

        # --- READ CONFIG VALUES ONE BY ONE WITH LOGGING ---
        bashio::log.debug "Reading service_name..."
        service_name=$(bashio::config "services[${i}].name")
        bashio::log.debug "Raw service_name: '${service_name}'"

        bashio::log.debug "Reading enabled..."
        service_enabled_raw=$(bashio::config "services[${i}].enabled")
        bashio::log.debug "Raw service_enabled: '${service_enabled_raw}'"
        # Handle enabled value robustly
        if [[ "$service_enabled_raw" == "false" ]]; then service_enabled="false"; else service_enabled="true"; fi
        bashio::log.debug "Processed service_enabled: '${service_enabled}'"

        bashio::log.debug "Reading ha_integration..."
        ha_integration=$(bashio::config "services[${i}].ha_integration")
        bashio::log.debug "Raw ha_integration: '${ha_integration}'"

        bashio::log.debug "Reading ha_domain..."
        ha_domain=$(bashio::config "services[${i}].ha_domain")
        bashio::log.debug "Raw ha_domain: '${ha_domain}'"

        bashio::log.debug "Reading ha_entity_pattern..."
        ha_entity_pattern=$(bashio::config "services[${i}].ha_entity_pattern")
        bashio::log.debug "Raw ha_entity_pattern: '${ha_entity_pattern}'"

        bashio::log.debug "Reading service_type..."
        service_type=$(bashio::config "services[${i}].service_type")
        bashio::log.debug "Raw service_type: '${service_type}'"

        bashio::log.debug "Reading service_port..."
        service_port=$(bashio::config "services[${i}].service_port")
        bashio::log.debug "Raw service_port: '${service_port}'"

        bashio::log.debug "Reading ip_attribute..."
        ip_attribute=$(bashio::config "services[${i}].ip_attribute")
        bashio::log.debug "Raw ip_attribute: '${ip_attribute}'"

        # --- END READ CONFIG VALUES ---
        bashio::log.info "Successfully read all config values for index ${i}."

        # Basic validation after reading all
        if [[ -z "$service_name" ]] || [[ -z "$service_type" ]] || [[ -z "$service_port" ]] || [[ -z "$ip_attribute" ]]; then
            bashio::log.warning "Required configuration field missing/empty for service index ${i}. Skipping."
            continue
        fi

        if [[ "$service_enabled" != "true" ]]; then
            bashio::log.debug "Skipping disabled service: ${service_name}"
            continue
        fi

        bashio::log.debug "Processing enabled service: ${service_name}"

        # --- Construct jq filter ---
        # ... (rest of the script: construct filter, filter entities, transform, process) ...

    done # End of looping through service rules


    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done