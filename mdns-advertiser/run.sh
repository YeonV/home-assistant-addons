#!/usr/bin/with-contenv bashio

# ==============================================================================
# Script constants
# ==============================================================================
HA_API_URL="http://supervisor/core/api"

# ==============================================================================
# Helper Functions
# ==============================================================================
publish_service() {
    local interface="$1"; local name="$2"; local type="$3"; local port="$4"; local ip="$5"; shift 5
    local txt_args=(); for txt in "$@"; do txt_args+=("$(printf '%q' "$txt")"); done

    bashio::log.debug "Publishing: Name='${name}', Type='${type}', Port=${port}, IP=${ip}, TXT='${txt_args[*]}' on Interface='${interface}'"
    if avahi-publish --interface "$(printf '%q' "$interface")" --subtype _home-assistant._sub."${type}" -a -R \
        "$(printf '%q' "$name")" "$(printf '%q' "$type")" "$port" "ip=${ip}" "${txt_args[@]}" >/dev/null 2>&1; then
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
if ! bashio::config.exists 'interface'; then
    bashio::log.fatal "Required configuration 'interface' is missing."
    exit 1
fi
[[ -z "${SUPERVISOR_TOKEN}" ]] && bashio::log.fatal "Supervisor token missing." && exit 1

# Read configuration
IFACE=$(bashio::config 'interface')
UPDATE_INTERVAL=$(bashio::config 'update_interval' 300) # Default 300
LOG_LEVEL=$(bashio::config 'log_level' 'info') # Default info
bashio::log.level "${LOG_LEVEL}"
bashio::log.info "Advertising on interface: ${IFACE}"
bashio::log.info "Update interval: ${UPDATE_INTERVAL} seconds"

# Main loop
while true; do
    bashio::log.debug "Starting update cycle..."

    # --- Fetch States ---
    bashio::log.debug "Attempting to fetch states from API: ${HA_API_URL}/states"
    http_response=$(curl -s -w "\nHTTP_STATUS:%{http_code}" -X GET \
        -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" -H "Content-Type: application/json" \
        "${HA_API_URL}/states")
    http_status=$(echo "$http_response" | grep HTTP_STATUS | cut -d':' -f2)
    states_json=$(echo "$http_response" | sed '$d')

    if [[ "$http_status" -ne 200 ]] || ! echo "$states_json" | jq -e . > /dev/null; then
        bashio::log.error "Failed to fetch or parse /api/states (HTTP: ${http_status}). Skipping cycle."
        sleep "${UPDATE_INTERVAL}"
        continue
    fi
    bashio::log.debug "Successfully fetched and parsed HA states."

    # --- Process Service Rules ---
    num_services=$(bashio::config 'services | length')
    bashio::log.debug "Found ${num_services} service configurations."

    for i in $(seq 0 $((num_services - 1))); do
        bashio::log.info "[MARKER 0] --- Processing Service Index: ${i} ---"

        # --- Read Service Config ---
        local service_name; service_name=$(bashio::config "services[${i}].name")
        local service_enabled_raw; service_enabled_raw=$(bashio::config "services[${i}].enabled")
        local service_enabled; if [[ "$service_enabled_raw" == "false" ]]; then service_enabled="false"; else service_enabled="true"; fi
        local entities_json; entities_json=$(bashio::config "services[${i}].entities") # Get the JSON array string
        local service_type; service_type=$(bashio::config "services[${i}].service_type")
        local service_port; service_port=$(bashio::config "services[${i}].service_port")
        local ip_source; ip_source=$(bashio::config "services[${i}].ip_source" "attribute") # Default attribute
        local ip_attribute; ip_attribute=$(bashio::config "services[${i}].ip_attribute")
        local name_source; name_source=$(bashio::config "services[${i}].name_source" "attribute") # Default attribute
        local name_attribute; name_attribute=$(bashio::config "services[${i}].name_attribute" "friendly_name") # Default friendly_name
        local filter_state; filter_state=$(bashio::config "services[${i}].filter_by_state")
        local filter_inverse_raw; filter_inverse_raw=$(bashio::config "services[${i}].filter_by_state_inverse")
        local filter_inverse; if [[ "$filter_inverse_raw" == "true" ]]; then filter_inverse="true"; else filter_inverse="false"; fi

        bashio::log.debug "Rule[${i}] Name: '${service_name}', Enabled: ${service_enabled}"
        bashio::log.debug "Rule[${i}] Entities JSON: ${entities_json}"
        bashio::log.debug "Rule[${i}] Service Type: ${service_type}, Port: ${service_port}"
        bashio::log.debug "Rule[${i}] IP Source: ${ip_source}, IP Attr: '${ip_attribute}'"
        bashio::log.debug "Rule[${i}] Name Source: ${name_source}, Name Attr: '${name_attribute}'"
        bashio::log.debug "Rule[${i}] State Filter: '${filter_state}', Inverse: ${filter_inverse}"

        # --- Validation & Skip Checks ---
        if [[ "$service_enabled" != "true" ]]; then bashio::log.debug "Rule[${i}] Skipping disabled service."; continue; fi
        if [[ -z "$service_name" ]] || [[ -z "$service_type" ]] || [[ -z "$service_port" ]]; then bashio::log.warning "Rule[${i}] Required field missing (name, type, port). Skipping."; continue; fi
        if [[ "$ip_source" == "attribute" && -z "$ip_attribute" ]]; then bashio::log.warning "Rule[${i}] ip_source is 'attribute' but ip_attribute missing. Skipping."; continue; fi
        if [[ "$name_source" == "attribute" && -z "$name_attribute" ]]; then bashio::log.warning "Rule[${i}] name_source is 'attribute' but name_attribute missing. Skipping."; continue; fi
        if ! echo "$entities_json" | jq -e '. | type == "array" and length > 0' > /dev/null; then bashio::log.warning "Rule[${i}] 'entities' list is missing, not an array, or empty. Skipping."; continue; fi

        # --- Process Entities specified in the config ---
        bashio::log.info "[MARKER 1] Processing configured entities for Rule[${i}]..."
        echo "$entities_json" | jq -c '.[]' | while IFS= read -r entity_id_json; do
            # Extract entity ID (remove quotes)
            target_entity_id=$(echo "$entity_id_json" | jq -r '.')
            bashio::log.debug "Rule[${i}] Checking entity: ${target_entity_id}"

            # --- Find this entity's state in the full states list ---
            entity_state_json=$(jq -c --arg entity_id "$target_entity_id" \
                '.[] | select(.entity_id == $entity_id)' <<< "$states_json")

            if [[ -z "$entity_state_json" ]] || [[ "$entity_state_json" == "null" ]]; then
                bashio::log.warning "Rule[${i}] Could not find state for specified entity: ${target_entity_id}. Skipping."
                continue
            fi
            bashio::log.trace "Rule[${i}] Found state JSON: ${entity_state_json}"

            # --- Apply State Filter ---
            if [[ -n "$filter_state" ]]; then
                current_state=$(jq -r '.state' <<< "$entity_state_json")
                bashio::log.trace "Rule[${i}] Checking state filter: Current='${current_state}', Filter='${filter_state}', Inverse=${filter_inverse}"
                if [[ "$filter_inverse" == "true" ]]; then
                    # Keep if state DOES NOT match filter_state
                    if [[ "$current_state" == "$filter_state" ]]; then
                         bashio::log.debug "Rule[${i}] Entity ${target_entity_id} skipped due to inverse state filter (state matched '${filter_state}')."
                         continue
                    fi
                else
                    # Keep if state DOES match filter_state (less common use case)
                     if [[ "$current_state" != "$filter_state" ]]; then
                         bashio::log.debug "Rule[${i}] Entity ${target_entity_id} skipped due to state filter (state did not match '${filter_state}')."
                         continue
                    fi
                fi
                bashio::log.trace "Rule[${i}] Entity ${target_entity_id} passed state filter."
             fi

            # --- Extract Name ---
            local target_friendly_name
            if [[ "$name_source" == "entity_id" ]]; then
                target_friendly_name=$(jq -r '.entity_id' <<< "$entity_state_json")
            else # Default to attribute
                target_friendly_name=$(jq -r ".attributes.\"${name_attribute}\" // .entity_id" <<< "$entity_state_json") # Fallback to entity_id
            fi
            bashio::log.trace "Rule[${i}] Extracted Name: '${target_friendly_name}'"

            # --- Extract IP ---
            local entity_ip
            if [[ "$ip_source" == "state" ]]; then
                entity_ip=$(jq -r '.state' <<< "$entity_state_json")
            else # Default to attribute
                entity_ip=$(jq -r ".attributes.\"${ip_attribute}\"" <<< "$entity_state_json")
            fi
            bashio::log.trace "Rule[${i}] Extracted IP: '${entity_ip}'"

            # --- Validate extracted values ---
            if [[ -z "$target_friendly_name" ]] || [[ "$target_friendly_name" == "null" ]]; then
                 bashio::log.warning "Rule[${i}] Failed to extract a valid name for ${target_entity_id}. Skipping."
                 continue
            fi
            if [[ -z "$entity_ip" ]] || [[ "$entity_ip" == "null" ]]; then
                 bashio::log.warning "Rule[${i}] Failed to extract a valid IP for ${target_entity_id} (Source: ${ip_source}). Skipping."
                 continue
            fi
             # Basic IP format check (optional but good)
             if ! [[ "$entity_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                 bashio::log.warning "Rule[${i}] Extracted IP '${entity_ip}' for ${target_entity_id} does not look like a valid IP address. Skipping."
                 continue
             fi

            # --- Publish ---
            bashio::log.info "Rule[${i}] Publishing mDNS for '${target_friendly_name}' (${target_entity_id}) -> ${entity_ip}"
            publish_service "${IFACE}" "${target_friendly_name}" "${service_type}" "${service_port}" "${entity_ip}" # TODO: Add TXT support later

        done # End while loop processing entities for this rule

        bashio::log.info "[MARKER 6] Reached end of FOR loop iteration for index ${i}."

    done # End of looping through service rules

    bashio::log.info "[MARKER 7] Exited FOR loop."
    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done # End while true