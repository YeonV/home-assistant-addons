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
        service_name=$(bashio::config "services[${i}].name")
        bashio::log.trace "Read service_name for index ${i}: '${service_name}'" # Add trace if needed

        # --- MODIFICATION START ---
        # Get the raw value, handle potential null/empty from bashio
        service_enabled_raw=$(bashio::config "services[${i}].enabled")
        bashio::log.trace "Raw service_enabled value for index ${i}: '${service_enabled_raw}'" # Add trace if needed

        # Default to 'true' if the value is not explicitly 'false'
        if [[ "$service_enabled_raw" == "false" ]]; then
            service_enabled="false"
        else
            service_enabled="true" # Treat empty, null, "true", or anything else as true
        fi
        bashio::log.trace "Processed service_enabled for index ${i}: '${service_enabled}'" # Add trace if needed
        # --- MODIFICATION END ---

        # --- GET OTHER CONFIG VALUES ---
        ha_integration=$(bashio::config "services[${i}].ha_integration" | jq -r '. // empty')
        ha_domain=$(bashio::config "services[${i}].ha_domain" | jq -r '. // empty')
        ha_entity_pattern=$(bashio::config "services[${i}].ha_entity_pattern" | jq -r '. // empty') # TODO: Implement pattern matching if needed
        service_type=$(bashio::config "services[${i}].service_type")
        service_port=$(bashio::config "services[${i}].service_port")
        ip_attribute=$(bashio::config "services[${i}].ip_attribute")
        # TODO: Handle TXT records configuration
        # --- END GET OTHER CONFIG VALUES ---


        # --- Now the check should work ---
        if [[ "$service_enabled" != "true" ]]; then
            bashio::log.debug "Skipping disabled service: ${service_name}"
            continue
        fi

        bashio::log.debug "Processing enabled service: ${service_name}" # Changed log message slightly

        if [[ "$service_enabled" != "true" ]]; then
            bashio::log.debug "Skipping disabled service: ${service_name}"
            continue
        fi

        bashio::log.debug "Processing service: ${service_name}"

        # Construct jq filter based on provided criteria
        jq_filter='.'
        if [[ -n "$ha_integration" ]]; then
            jq_filter+=" | select(.attributes.integration == \"${ha_integration}\")"
        elif [[ -n "$ha_domain" ]]; then
            jq_filter+=" | select(.entity_id | startswith(\"${ha_domain}.\"))"
        elif [[ -n "$ha_entity_pattern" ]]; then
            jq_filter+=" | select(.entity_id | startswith(\"${ha_entity_pattern%???}\"))"
        else
            bashio::log.warning "No filter criteria defined for service '${service_name}'. Skipping."
            continue
        fi
        # --- Ensure ip_attribute is correctly escaped if it contains special chars ---
        # --- Though 'ip_address' should be safe ---
        jq_filter+=" | select(.attributes.\"${ip_attribute}\" != null)"

        bashio::log.debug "Constructed jq filter: ${jq_filter}" # Log the exact filter

        # --- STEP 1: Filter Only ---
        bashio::log.debug "Attempting to filter entities..."
        filtered_entities_json=$(echo "$states_json" | jq -c ".[] | ${jq_filter}")
        filter_exit_code=$? # Capture exit code of jq

        if [[ $filter_exit_code -ne 0 ]]; then
            bashio::log.error "JQ filtering failed with exit code ${filter_exit_code}!"
            bashio::log.debug "Filter was: ${jq_filter}"
            # Log first few chars of input to see if it looks ok
            bashio::log.debug "Input JSON start: $(echo "$states_json" | head -c 200)"
            # Maybe skip to next service rule or next main loop iteration
            continue
        fi

        # Check if any entities were found
        if [[ -z "$filtered_entities_json" ]]; then
            bashio::log.info "No entities matched the filter for service '${service_name}'."
            continue # Move to the next service rule
        fi
        bashio::log.debug "Filtering successful. Filtered entities (first 500 chars): $(echo "$filtered_entities_json" | head -c 500)"

        # --- STEP 2: Transform Filtered Entities ---
        bashio::log.debug "Attempting to transform filtered entities..."
        # IMPORTANT: Process each filtered JSON object individually if jq expects one object per input line
        transformed_output=""
        echo "$filtered_entities_json" | while IFS= read -r single_entity_json; do
            # Feed one entity JSON object at a time to the transformation jq
            current_transformed=$(echo "$single_entity_json" | jq -c "{name: .attributes.friendly_name // .entity_id, ip: .attributes.\"${ip_attribute}\"}")
            transform_exit_code=$?
            if [[ $transform_exit_code -ne 0 ]]; then
                bashio::log.error "JQ transformation failed with exit code ${transform_exit_code} for one entity!"
                bashio::log.debug "Problematic filtered entity JSON: ${single_entity_json}"
                # Decide: skip this entity or abort the whole service? For now, just log and skip entity.
                continue
            fi
            # Append successful transformation to overall output, separated by newline
            transformed_output+="${current_transformed}"$'\n'
        done

        # Check if any transformations succeeded
        if [[ -z "$transformed_output" ]]; then
            bashio::log.warning "Transformation resulted in empty output, although filtering found entities. Check transformation logic."
            continue
        fi
        bashio::log.debug "Transformation successful."


        # --- STEP 3: Pipe to the processing loop ---
        # Remove trailing newline before piping
        printf "%s" "$transformed_output" | \
        while IFS= read -r entity_info; do
            # --- This loop should now receive correctly formed {name:..., ip:...} lines ---
            if [[ -z "$entity_info" ]]; then continue; fi

            bashio::log.debug "Processing entity_info line: ${entity_info}"

            entity_name=$(echo "$entity_info" | jq -r '.name')
            entity_ip=$(echo "$entity_info" | jq -r '.ip')
            # Check exit codes for these inner jq calls too if needed

            bashio::log.debug "Extracted Name: '${entity_name}', Extracted IP: '${entity_ip}'"

            if [[ -z "$entity_name" ]] || [[ -z "$entity_ip" ]]; then
                bashio::log.warning "Could not extract name or IP within loop. Info: ${entity_info}"
                continue
            fi

            # Publish the service
            publish_service "${IFACE}" "${entity_name}" "${service_type}" "${service_port}" "${entity_ip}"

        done # End of processing entities for one service rule

    done # End of looping through service rules

    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done