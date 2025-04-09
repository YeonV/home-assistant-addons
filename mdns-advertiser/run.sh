#!/usr/bin/with-contenv bashio

# ==============================================================================
# Script constants & Helper Functions (Keep as before)
# ==============================================================================
HA_API_URL="http://supervisor/core/api"
publish_service() {
    local interface="$1"; local name="$2"; local type="$3"; local port="$4"; local ip="$5"; shift 5
    local txt_args=(); for txt in "$@"; do txt_args+=("$(printf '%q' "$txt")"); done

    bashio::log.debug "Publishing: Name='${name}', Type='${type}', Port=${port}, IP=${ip}, TXT='${txt_args[*]}' on Interface='${interface}'"
    # --- TEMPORARILY REMOVED --subtype argument ---
    if avahi-publish \
        --interface "$(printf '%q' "$interface")" \
        -a \
        -R \
        "$(printf '%q' "$name")" \
        "$(printf '%q' "$type")" \
        "$port" \
        "ip=${ip}" \
        "${txt_args[@]}" >/dev/null 2>&1; then
    # --- END TEMPORARY REMOVAL ---
        bashio::log.trace "Successfully published '${name}' (${ip})"
    else
        bashio::log.warning "Failed to publish '${name}' (${ip})"
    fi
}

# ==============================================================================
# Main Script Logic
# ==============================================================================
ADDON_NAME=$(bashio::addon.name)
ADDON_VERSION=$(bashio::addon.version)
bashio::log.info "Starting ${ADDON_NAME} v${ADDON_VERSION}..."

# Validate SUPERVISOR_TOKEN & interface
if ! bashio::config.exists 'interface'; then bashio::log.fatal "Config 'interface' missing."; exit 1; fi
[[ -z "${SUPERVISOR_TOKEN}" ]] && bashio::log.fatal "Supervisor token missing." && exit 1

# Read configuration
IFACE=$(bashio::config 'interface')
UPDATE_INTERVAL=$(bashio::config 'update_interval' 300)
LOG_LEVEL=$(bashio::config 'log_level' 'info')
bashio::log.level "${LOG_LEVEL}"
bashio::log.info "Advertising on interface: ${IFACE}"
bashio::log.info "Update interval: ${UPDATE_INTERVAL} seconds"

# REMOVED test_device logging

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
    services_config_json=$(bashio::config 'services')
    if ! echo "$services_config_json" | jq -e '. | type == "array"' > /dev/null; then
        bashio::log.warning "Configuration 'services' is not a valid JSON array. Skipping cycle."
        sleep "${UPDATE_INTERVAL}"
        continue
    fi

    num_services=$(echo "$services_config_json" | jq 'length')
    bashio::log.debug "Found ${num_services} service configurations."

    for i in $(seq 0 $((num_services - 1))); do
        bashio::log.info "[MARKER 0] --- Processing Service Index: ${i} ---"
        set -x 
        # --- Extract config for this index using jq ---
        current_service_config=$(echo "$services_config_json" | jq -c ".[${i}]") # Get the object for index i

        # --- Read values from the extracted JSON object ---
        # Use jq with checks for null/defaults
        service_name=$(echo "$current_service_config" | jq -r '.name // empty')
        service_enabled_raw=$(echo "$current_service_config" | jq -r '.enabled // "true"') # Default true if null
        service_enabled="true"; [[ "$service_enabled_raw" == "false" ]] && service_enabled="false"
        service_type=$(echo "$current_service_config" | jq -r '.service_type // empty')
        service_port=$(echo "$current_service_config" | jq -r '.service_port // empty')
        ip_source=$(echo "$current_service_config" | jq -r '.ip_source // "state"') # Default state
        ip_attribute=$(echo "$current_service_config" | jq -r '.ip_attribute // empty')
        name_source=$(echo "$current_service_config" | jq -r '.name_source // "attribute"') # Default attribute
        name_attribute=$(echo "$current_service_config" | jq -r '.name_attribute // "friendly_name"') # Default friendly_name
        filter_state=$(echo "$current_service_config" | jq -r '.filter_by_state // empty')
        filter_inverse_raw=$(echo "$current_service_config" | jq -r '.filter_by_state_inverse // "false"') # Default false
        filter_inverse="false"; [[ "$filter_inverse_raw" == "true" ]] && filter_inverse="true"
        ha_integration=$(echo "$current_service_config" | jq -r '.ha_integration // empty')
        ha_domain=$(echo "$current_service_config" | jq -r '.ha_domain // empty')
        ha_entity_pattern=$(echo "$current_service_config" | jq -r '.ha_entity_pattern // empty')

        # --- Log optional entities list if present ---
        user_provided_entities=() # Bash array to store validated entity IDs from config
        log_user_entities=false
        
        if bashio::config.exists "services[${i}].entities"; then

            entities_json="$(bashio::config "services[${i}].entities")" # Read the list again if needed, or use variable from above
            if echo "$entities_json" | jq -e '. | type == "array" and length > 0' > /dev/null; then
                bashio::log.notice "Rule[${i}] Optional 'entities' list provided in config: ${entities_json}"
                log_user_entities=true
                # --- NEW: Validate and Log Real Entities from Input List ---
                bashio::log.debug "Rule[${i}] Validating provided optional entities..."
                found_real_entities=()
                not_found_entities=()
                echo "$entities_json" | jq -cr '.[]' | while IFS= read -r entity_id_from_config; do
                    # Check if this entity exists in our fetched states
                    if jq -e --arg entity_id "$entity_id_from_config" \
                    '.[] | select(.entity_id == $entity_id)' <<< "$states_json" > /dev/null; then
                        bashio::log.trace "Rule[${i}]   Found entity from config list: ${entity_id_from_config}"
                        found_real_entities+=("$entity_id_from_config")
                    else
                        bashio::log.trace "Rule[${i}]   Entity from config list NOT FOUND in current states: ${entity_id_from_config}"
                        not_found_entities+=("$entity_id_from_config")
                    fi
                done
                if [[ ${#found_real_entities[@]} -gt 0 ]]; then
                    bashio::log.notice "Rule[${i}] Real entities found based on optional config list: ${found_real_entities[*]}"
                fi
                if [[ ${#not_found_entities[@]} -gt 0 ]]; then
                    bashio::log.warning "Rule[${i}] Entities from optional config list NOT FOUND in current states: ${not_found_entities[*]}"
                fi
                # --- END NEW VALIDATION ---
            else
                bashio::log.debug "Rule[${i}] Optional 'entities' list is present but empty or not an array."
            fi
        fi

        # --- Apply default pattern logic ---
        use_default_pattern=false
        if [[ -z "$ha_integration" && -z "$ha_domain" && -z "$ha_entity_pattern" ]]; then
            bashio::log.debug "Rule[${i}] No filter specified, using default pattern 'sensor.*_ip'."
            ha_entity_pattern="sensor.*_ip"
            use_default_pattern=true
        fi
        set +x

        # --- Log optional entities list if present ---
        if bashio::config.exists "services[${i}].entities"; then
            entities_json="$(bashio::config "services[${i}].entities")"
             if echo "$entities_json" | jq -e '. | type == "array" and length > 0' > /dev/null; then
                bashio::log.notice "Rule[${i}] Optional 'entities' list provided (logging only): ${entities_json}"
             fi
        fi

        # --- Log final processed values ---
        bashio::log.debug "Rule[${i}] Name: '${service_name}', Enabled: ${service_enabled}"
        bashio::log.debug "Rule[${i}] Service Type: ${service_type}, Port: ${service_port}"
        bashio::log.debug "Rule[${i}] IP Source: ${ip_source}, IP Attr: '${ip_attribute}'"
        bashio::log.debug "Rule[${i}] Name Source: ${name_source}, Name Attr: '${name_attribute}'"
        bashio::log.debug "Rule[${i}] State Filter: '${filter_state}', Inverse: ${filter_inverse}"
        bashio::log.debug "Rule[${i}] Filter Used: Integration='${ha_integration}', Domain='${ha_domain}', Pattern='${ha_entity_pattern}' (Default applied: ${use_default_pattern})"

        # --- Validation & Skip Checks ---
        if [[ "$service_enabled" != "true" ]]; then bashio::log.debug "Rule[${i}] Skipping disabled service."; continue; fi
        # ... (other validation checks) ...

        # --- Construct JQ Filter (using the PROCESSED variables) ---
        bashio::log.info "[MARKER 1] Constructing filter..."
        jq_filter='.' # Start with all entities

        # Apply primary filter (Integration, Domain, or Pattern)
        if [[ -n "$ha_integration" ]]; then
            bashio::log.debug "Using filter: integration = ${ha_integration}"
            jq_filter+=" | select(.attributes.integration == \"${ha_integration}\")"
        elif [[ -n "$ha_domain" ]]; then
            bashio::log.debug "Using filter: domain = ${ha_domain}."
            jq_filter+=" | select(.entity_id | startswith(\"${ha_domain}.\"))"
        elif [[ -n "$ha_entity_pattern" ]]; then
            bashio::log.debug "Using filter: entity pattern = ${ha_entity_pattern}"
            # Use test() for regex matching
            escaped_pattern=$(echo "$ha_entity_pattern" | sed -e 's/[.^$*+?(){}|[\]\\]/\\&/g' -e 's/\//\\\//g') # Escape regex chars AND forward slash for jq
            jq_filter+=" | select(.entity_id | test(\"^${escaped_pattern}\"))"
        # No 'else' needed because default pattern is applied above if all were empty
        fi

        # Apply state filter
        if [[ -n "$filter_state" ]]; then
            op_str="=="; [[ "$filter_inverse" == "true" ]] && op_str="!="
            bashio::log.debug "Adding state filter: state ${op_str} '${filter_state}'"
            op="=="; [[ "$filter_inverse" == "true" ]] && op="!="
            jq_filter+=" | select(.state ${op} \"${filter_state}\")"
        fi

        # Apply IP source check
        if [[ "$ip_source" == "state" ]]; then
            # Ensure state is not null, empty, unavailable, or unknown
            jq_filter+=" | select(.state != null and .state != \"\" and .state != \"unavailable\" and .state != \"unknown\")"
        else
            jq_filter+=" | select(.attributes.\"${ip_attribute}\" != null)"
        fi
        bashio::log.debug "Constructed jq filter: ${jq_filter}"


        # --- Filter Entities ---
        bashio::log.info "[MARKER 2] Starting entity filtering..."
        filtered_entities_json=$(jq -c "[.[] | ${jq_filter}]" <<< "$states_json")
        filter_exit_code=$?
        if [[ $filter_exit_code -ne 0 ]]; then bashio::log.error "JQ filtering failed (EC: ${filter_exit_code})!"; continue; fi
        if [[ "$(jq -c 'length == 0' <<< "$filtered_entities_json")" == "true" ]]; then bashio::log.info "Rule[${i}] No entities matched the filter."; continue; fi
        bashio::log.debug "Filtering successful. Found $(jq -c length <<< "$filtered_entities_json") entities."

        # --- Process Each Filtered Entity ---
        bashio::log.info "[MARKER 4] Processing filtered entities..."
        echo "$filtered_entities_json" | jq -c '.[]' | while IFS= read -r entity_state_json; do
            bashio::log.trace "Rule[${i}] Processing filtered entity JSON: ${entity_state_json}"

           # --- Debug and Trim Name ---
            bashio::log.debug "Name before trimming: '${target_friendly_name}'"
            # Log hex representation to check for weird spaces
            bashio::log.trace "Name before trimming (hex): $(printf '%s' "$target_friendly_name" | xxd -p)"

            original_name_for_log="$target_friendly_name"
            target_friendly_name="${target_friendly_name% IP}" # Attempt trimming

            bashio::log.debug "Name AFTER trimming: '${target_friendly_name}'"
            bashio::log.trace "Name AFTER trimming (hex): $(printf '%s' "$target_friendly_name" | xxd -p)"

            if [[ "$original_name_for_log" == "$target_friendly_name" ]]; then
                bashio::log.debug "Trimming ' IP' had NO effect on the name."
            else
                bashio::log.info "Successfully trimmed ' IP' from name. Original: '${original_name_for_log}'"
            fi
            # --- End Debug and Trim ---
            # Log if changed
            if [[ "$original_name_for_log" != "$target_friendly_name" ]]; then
                bashio::log.trace "Rule[${i}] Removed trailing ' IP' from name. Original: '${original_name_for_log}', New: '${target_friendly_name}'"
            fi
            # --- END NEW ---

            # --- Extract IP ---
            entity_ip=""
            if [[ "$ip_source" == "state" ]]; then
                entity_ip=$(jq -r '.state' <<< "$entity_state_json")
            else # Default attribute
                entity_ip=$(jq -r ".attributes.\"${ip_attribute}\"" <<< "$entity_state_json")
            fi

            # --- Validation ---
            if [[ -z "$target_friendly_name" ]] || [[ "$target_friendly_name" == "null" ]]; then bashio::log.warning "Rule[${i}] Invalid name. JSON: ${entity_state_json}. Skip."; continue; fi
            if [[ -z "$entity_ip" ]] || [[ "$entity_ip" == "null" ]]; then bashio::log.warning "Rule[${i}] Invalid IP. JSON: ${entity_state_json}. Skip."; continue; fi
            if ! [[ "$entity_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then bashio::log.warning "Rule[${i}] Invalid IP format '${entity_ip}'. JSON: ${entity_state_json}. Skip."; continue; fi

            # --- Publish ---
            bashio::log.info "Rule[${i}] Publishing mDNS for '${target_friendly_name}' -> ${entity_ip}"
            publish_service "${IFACE}" "${target_friendly_name}" "${service_type}" "${service_port}" "${entity_ip}"

        done # End while loop processing filtered entities

        bashio::log.info "[MARKER 6] Reached end of FOR loop iteration for index ${i}."

    done # End of looping through service rules

    bashio::log.info "[MARKER 7] Exited FOR loop."
    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done # End while true