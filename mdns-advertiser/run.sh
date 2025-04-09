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
    bashio::log.debug "Received Response Body (first 100 chars): $(echo "$states_json" | head -c 100)"

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

    # Now try parsing with jq
    if ! echo "$states_json" | jq -e . > /dev/null; then
        bashio::log.error "Failed to parse states JSON from Home Assistant API."
        bashio::log.error "Response Body was: ${states_json}" # Log the problematic body
        sleep "${UPDATE_INTERVAL}"
        continue
    fi

    # Get configured services from options.json using jq
    num_services=$(bashio::config 'services | length')
    bashio::log.debug "Found ${num_services} service configurations."

    # Loop through each configured service rule
    for i in $(seq 0 $((num_services - 1))); do
        service_name=$(bashio::config "services[${i}].name")
        service_enabled=$(bashio::config "services[${i}].enabled")

        if [[ "$service_enabled" != "true" ]]; then
            bashio::log.debug "Skipping disabled service: ${service_name}"
            continue
        fi

        bashio::log.debug "Processing service: ${service_name}"

        # Get filter criteria
        ha_integration=$(bashio::config "services[${i}].ha_integration" | jq -r '. // empty')
        ha_domain=$(bashio::config "services[${i}].ha_domain" | jq -r '. // empty')
        ha_entity_pattern=$(bashio::config "services[${i}].ha_entity_pattern" | jq -r '. // empty') # TODO: Implement pattern matching if needed
        service_type=$(bashio::config "services[${i}].service_type")
        service_port=$(bashio::config "services[${i}].service_port")
        ip_attribute=$(bashio::config "services[${i}].ip_attribute")
        # TODO: Handle TXT records configuration

        # Construct jq filter based on provided criteria
        jq_filter='.'
        if [[ -n "$ha_integration" ]]; then
            jq_filter+=" | select(.attributes.integration == \"${ha_integration}\")" # Assuming integration attribute exists - MAY NEED ADJUSTMENT
            # Note: Often better to filter by domain or entity ID prefix if integration attribute isn't reliable
        elif [[ -n "$ha_domain" ]]; then
            jq_filter+=" | select(.entity_id | startswith(\"${ha_domain}.\"))"
        elif [[ -n "$ha_entity_pattern" ]]; then
             # Simple prefix matching for now
             jq_filter+=" | select(.entity_id | startswith(\"${ha_entity_pattern%???}\"))" # Basic wildcard simulation
        else
            bashio::log.warning "No filter criteria (integration, domain, or pattern) defined for service '${service_name}'. Skipping."
            continue
        fi

        # Add filter for state = 'on' or 'available' maybe? Or just check IP attribute exists
        jq_filter+=" | select(.attributes.\"${ip_attribute}\" != null)"

        # Extract needed info using jq
        # Using 'c' option for compact output, 'r' for raw string output
        echo "$states_json" | jq -c ".[] | ${jq_filter} | {name: .attributes.friendly_name, ip: .attributes.\"${ip_attribute}\"}" | \
        while IFS= read -r entity_info; do
            if [[ -z "$entity_info" ]]; then continue; fi

            entity_name=$(echo "$entity_info" | jq -r '.name')
            entity_ip=$(echo "$entity_info" | jq -r '.ip')

            if [[ -z "$entity_name" ]] || [[ -z "$entity_ip" ]]; then
                bashio::log.warning "Could not extract name or IP for an entity in service '${service_name}'. Info: ${entity_info}"
                continue
            fi

            # TODO: Process and add TXT records here if configured

            # Publish the service
            publish_service "${IFACE}" "${entity_name}" "${service_type}" "${service_port}" "${entity_ip}" # Add TXT args here

        done # End of processing entities for one service rule

    done # End of looping through service rules

    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done