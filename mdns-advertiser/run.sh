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

    # Loop through each configured service rule
    for i in $(seq 0 $((num_services - 1))); do
        # --- LOG ENTRY INTO LOOP ITERATION ---
        bashio::log.info "[MARKER 0] --- Processing Service Index: ${i} ---"
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
        # Handle potential null from bashio::config explicitly for string vars
        [[ "$ha_integration" == "null" ]] && ha_integration=""

        bashio::log.debug "Reading ha_domain..."
        ha_domain=$(bashio::config "services[${i}].ha_domain")
        bashio::log.debug "Raw ha_domain: '${ha_domain}'"
        [[ "$ha_domain" == "null" ]] && ha_domain=""

        bashio::log.debug "Reading ha_entity_pattern..."
        ha_entity_pattern=$(bashio::config "services[${i}].ha_entity_pattern")
        bashio::log.debug "Raw ha_entity_pattern: '${ha_entity_pattern}'"
        [[ "$ha_entity_pattern" == "null" ]] && ha_entity_pattern=""

        bashio::log.debug "Reading service_type..."
        service_type=$(bashio::config "services[${i}].service_type")
        bashio::log.debug "Raw service_type: '${service_type}'"

        bashio::log.debug "Reading service_port..."
        service_port=$(bashio::config "services[${i}].service_port")
        bashio::log.debug "Raw service_port: '${service_port}'"

        bashio::log.debug "Reading ip_attribute..."
        ip_attribute=$(bashio::config "services[${i}].ip_attribute")
        bashio::log.debug "Raw ip_attribute: '${ip_attribute}'"

        # TODO: Read TXT records config here if implementing

        # --- END READ CONFIG VALUES ---
        bashio::log.info "Successfully read all config values for index ${i}."

        # Basic validation after reading all
        if [[ -z "$service_name" ]] || [[ -z "$service_type" ]] || [[ -z "$service_port" ]] || [[ -z "$ip_attribute" ]]; then
            bashio::log.warning "Required configuration field missing/empty for service index ${i} (name, type, port, ip_attribute). Skipping."
            continue
        fi

        if [[ "$service_enabled" != "true" ]]; then
            bashio::log.debug "Skipping disabled service: ${service_name}"
            continue
        fi

        bashio::log.debug "Processing enabled service: ${service_name}"

        # --- ADD MARKER 1 ---
        bashio::log.info "[MARKER 1] Constructing filter..."
        # Construct jq filter based on provided criteria
        jq_filter='.'
        if [[ -n "$ha_integration" ]]; then
            bashio::log.debug "Using filter: integration = ${ha_integration}"
            jq_filter+=" | select(.attributes.integration == \"${ha_integration}\")"
        elif [[ -n "$ha_domain" ]]; then
            bashio::log.debug "Using filter: domain = ${ha_domain}."
            jq_filter+=" | select(.entity_id | startswith(\"${ha_domain}.\"))"
        elif [[ -n "$ha_entity_pattern" ]]; then
            bashio::log.debug "Using filter: entity pattern = ${ha_entity_pattern}"
            # Simple prefix matching for now - adjust if needed for more complex patterns
            # Remove potential trailing wildcard for startswith
            pattern_prefix="${ha_entity_pattern%\*}"
            jq_filter+=" | select(.entity_id | startswith(\"${pattern_prefix}\"))"
        else
            bashio::log.warning "No filter criteria (integration, domain, or pattern) defined for service '${service_name}'. Skipping."
            continue
        fi
        # Ensure ip_attribute is correctly escaped if it contains special chars (unlikely for 'ip_address')
        jq_filter+=" | select(.attributes.\"${ip_attribute}\" != null)"
        bashio::log.debug "Constructed jq filter: ${jq_filter}"

        # --- ADD MARKER 2 ---
        bashio::log.info "[MARKER 2] Starting STEP 1: Filter Only..."
        # --- STEP 1: Filter Only ---
        bashio::log.debug "Attempting to filter entities..."
        # Use process substitution to avoid issues with large states_json? Safer.
        filtered_entities_json=$(jq -c ".[] | ${jq_filter}" <<< "$states_json")
        filter_exit_code=$? # Capture exit code of jq

        if [[ $filter_exit_code -ne 0 ]]; then
            bashio::log.error "JQ filtering failed with exit code ${filter_exit_code}!"
            bashio::log.debug "Filter was: ${jq_filter}"
            bashio::log.debug "Input JSON start (first 200 chars): $(echo "$states_json" | head -c 200)"
            continue # Skip to next service rule
        fi

        # Check if any entities were found
        if [[ -z "$filtered_entities_json" ]]; then
            bashio::log.info "No entities matched the filter for service '${service_name}'."
            continue # Move to the next service rule
        fi
        bashio::log.debug "Filtering successful. Filtered entities (first 500 chars): $(echo "$filtered_entities_json" | head -c 500)"

        # --- ADD MARKER 3 ---
        bashio::log.info "[MARKER 3] Starting STEP 2: Transform Filtered Entities..."
        # --- STEP 2: Transform Filtered Entities ---
        transformed_output=""
        # Use process substitution again for safety
        while IFS= read -r single_entity_json; do
            # Feed one entity JSON object at a time to the transformation jq
            current_transformed=$(jq -c "{name: .attributes.friendly_name // .entity_id, ip: .attributes.\"${ip_attribute}\"}" <<< "$single_entity_json")
            transform_exit_code=$?
            if [[ $transform_exit_code -ne 0 ]]; then
                bashio::log.error "JQ transformation failed with exit code ${transform_exit_code} for one entity!"
                bashio::log.debug "Problematic filtered entity JSON: ${single_entity_json}"
                # Log and skip this problematic entity
                continue
            fi
            # Append successful transformation to overall output, separated by newline
            transformed_output+="${current_transformed}"$'\n'
        done <<< "$filtered_entities_json" # Pipe filtered JSON line by line

        # Check if any transformations succeeded
        if [[ -z "$transformed_output" ]]; then
            bashio::log.warning "Transformation resulted in empty output, although filtering found entities. Check transformation logic or entity data."
            continue # Move to the next service rule
        fi
        bashio::log.debug "Transformation successful."


        # --- ADD MARKER 4 ---
        bashio::log.info "[MARKER 4] Starting STEP 3: Processing Loop..."
        # --- STEP 3: Pipe to the processing loop ---
        # Use printf to avoid issues with echo interpretation and trailing newline
        # Process the transformed output line by line
        printf "%s" "$transformed_output" | while IFS= read -r entity_info; do
            # Check if line is empty (can happen with printf if input was empty despite earlier check)
            if [[ -z "$entity_info" ]]; then continue; fi

            bashio::log.debug "Processing entity_info line: ${entity_info}"

            # Use <<< (here string) for safety feeding variable to jq
            entity_name=$(jq -r '.name' <<< "$entity_info")
            name_exit_code=$?
            entity_ip=$(jq -r '.ip' <<< "$entity_info")
            ip_exit_code=$?

            if [[ $name_exit_code -ne 0 ]] || [[ $ip_exit_code -ne 0 ]]; then
                 bashio::log.error "Inner JQ extraction failed (Name EC: ${name_exit_code}, IP EC: ${ip_exit_code}). Entity Info: ${entity_info}"
                 continue
            fi

            bashio::log.debug "Extracted Name: '${entity_name}', Extracted IP: '${entity_ip}'"

            if [[ -z "$entity_name" ]] || [[ -z "$entity_ip" ]]; then
                bashio::log.warning "Could not extract name or IP within loop (result was empty). Info: ${entity_info}"
                continue
            fi

            # --- TODO: Implement TXT Record extraction and assembly here ---
            # Example: txt_records_array=("key1=val1" "key2=val2")
            # Then pass "${txt_records_array[@]}" to publish_service

            # Publish the service
            publish_service "${IFACE}" "${entity_name}" "${service_type}" "${service_port}" "${entity_ip}" # Add TXT args here

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