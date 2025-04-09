#!/usr/bin/with-contenv bashio

# ==============================================================================
# Script constants & Helper Functions
# ==============================================================================
HA_API_URL="http://supervisor/core/api"

publish_service() {
    local interface="$1"; local name="$2"; local type="$3"; local port="$4"; local ip="$5"; shift 5
    local txt_args=(); for txt in "$@"; do txt_args+=("$(printf '%q' "$txt")"); done

    bashio::log.debug "Attempting Publish: Name='${name}', Type='${type}', Port=${port}, IP=${ip}, TXT='${txt_args[*]}'"

    # REMOVED redirection >/dev/null 2>&1
    # ADDED -f flag
    if avahi-publish -f -a -R \
        "$(printf '%q' "$name")" "$(printf '%q' "$type")" "$port" "ip=${ip}" "${txt_args[@]}"; then
        bashio::log.trace "avahi-publish command finished for '${name}' (${ip}). Check for errors above if publish failed."
        # We can't rely on exit code alone with -f, but success usually means no errors printed
    else
        # This else block might not even be reached if -f suppresses errors that cause non-zero exit
        bashio::log.warning "avahi-publish command potentially failed for '${name}' (${ip}). Check output."
    fi
}

# ==============================================================================
# Main Script Logic
# ==============================================================================
ADDON_NAME=$(bashio::addon.name)
ADDON_VERSION=$(bashio::addon.version)
bashio::log.info "Starting ${ADDON_NAME} v${ADDON_VERSION}..."

# Validate required config
if ! bashio::config.exists 'interface'; then bashio::log.fatal "Config 'interface' missing."; exit 1; fi
[[ -z "${SUPERVISOR_TOKEN}" ]] && bashio::log.fatal "Supervisor token missing." && exit 1

# Read global config
IFACE=$(bashio::config 'interface')
UPDATE_INTERVAL=$(bashio::config 'update_interval' 300)
LOG_LEVEL=$(bashio::config 'log_level' 'info')
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

    # Validate API Response
    if [[ "$http_status" -ne 200 ]] || ! echo "$states_json" | jq -e . > /dev/null; then
        bashio::log.error "Failed to fetch or parse /api/states (HTTP: ${http_status}). Skipping cycle."
        sleep "${UPDATE_INTERVAL}"
        continue
    fi
    bashio::log.debug "Successfully fetched and parsed HA states."

    # --- Process Service Rules ---
    # Get count first
    num_services=$(bashio::config 'services | length')
    if ! [[ "$num_services" =~ ^[0-9]+$ ]]; then
        bashio::log.warning "Could not determine number of services from config. Raw value: '${num_services}'. Skipping cycle."
        sleep "${UPDATE_INTERVAL}"
        continue
    fi
    bashio::log.debug "Found ${num_services} service configurations."

    for i in $(seq 0 $((num_services - 1))); do
        bashio::log.info "[MARKER 0] --- Processing Service Index: ${i} ---"
        # Wrap config reading in block to contain potential errors? Maybe not needed now.
        # set -x # Optional: Enable for extreme debug during config read

        # --- Read config values using indexed access ---
        service_name_raw="$(bashio::config "services[${i}].name")"
        service_enabled_raw="$(bashio::config "services[${i}].enabled")"
        service_type_raw="$(bashio::config "services[${i}].service_type")"
        service_port_raw="$(bashio::config "services[${i}].service_port")"
        ip_source_raw="$(bashio::config "services[${i}].ip_source")"
        ip_attribute_raw="$(bashio::config "services[${i}].ip_attribute")"
        name_source_raw="$(bashio::config "services[${i}].name_source")"
        name_attribute_raw="$(bashio::config "services[${i}].name_attribute")"
        filter_state_raw="$(bashio::config "services[${i}].filter_by_state")"
        filter_inverse_raw="$(bashio::config "services[${i}].filter_by_state_inverse")"
        ha_integration_raw="$(bashio::config "services[${i}].ha_integration")"
        ha_domain_raw="$(bashio::config "services[${i}].ha_domain")"
        ha_entity_pattern_raw="$(bashio::config "services[${i}].ha_entity_pattern")"

        # --- Process values, apply defaults, handle nulls ---
        service_name="$service_name_raw"
        service_enabled="true"; [[ "$service_enabled_raw" == "false" ]] && service_enabled="false"
        service_type="$service_type_raw"
        service_port="$service_port_raw"
        ip_source="$ip_source_raw"; [[ -z "$ip_source" || "$ip_source" == "null" ]] && ip_source="state"
        ip_attribute="$ip_attribute_raw"; [[ "$ip_attribute" == "null" ]] && ip_attribute=""
        name_source="$name_source_raw"; [[ -z "$name_source" || "$name_source" == "null" ]] && name_source="attribute"
        name_attribute="$name_attribute_raw"; [[ -z "$name_attribute" || "$name_attribute" == "null" ]] && name_attribute="friendly_name"
        filter_state="$filter_state_raw"; [[ "$filter_state" == "null" ]] && filter_state=""
        filter_inverse="false"; [[ "$filter_inverse_raw" == "true" ]] && filter_inverse="true"
        ha_integration="$ha_integration_raw"; [[ "$ha_integration" == "null" ]] && ha_integration=""
        ha_domain="$ha_domain_raw"; [[ "$ha_domain" == "null" ]] && ha_domain=""
        ha_entity_pattern="$ha_entity_pattern_raw"; [[ "$ha_entity_pattern" == "null" ]] && ha_entity_pattern=""

        # set +x # Optional: Disable verbose tracing if enabled above

        # --- Apply default pattern logic ---
        use_default_pattern=false
        if [[ -z "$ha_integration" && -z "$ha_domain" && -z "$ha_entity_pattern" ]]; then
            bashio::log.debug "Rule[${i}] No filter specified, using default pattern 'sensor.*_ip'."
            ha_entity_pattern="sensor.*_ip"
            use_default_pattern=true
        fi

        # --- Log optional entities list if present ---
        if bashio::config.exists "services[${i}].entities"; then
            entities_json="$(bashio::config "services[${i}].entities")" # Read the list
             # Validate it's a non-empty array before proceeding
             if echo "$entities_json" | jq -e '. | type == "array" and length > 0' > /dev/null; then
                bashio::log.notice "Rule[${i}] Optional 'entities' list provided in config: ${entities_json}"
                # --- Validate and Log Real Entities from Input List ---
                bashio::log.debug "Rule[${i}] Validating provided optional entities..."
                found_real_entities=() # Use simple var names, ensure they aren't used elsewhere
                not_found_entities=()
                # Use jq to iterate array elements safely
                echo "$entities_json" | jq -cr '.[]' | while IFS= read -r entity_id_from_config; do
                    # Check if this entity exists in our fetched states
                    # Use -e flag for jq to set exit code based on result (0 if found, non-zero if not)
                    if jq -e --arg entity_id "$entity_id_from_config" \
                       '.[] | select(.entity_id == $entity_id) | true' <<< "$states_json" > /dev/null; then
                        bashio::log.trace "Rule[${i}]   Found entity from config list: ${entity_id_from_config}"
                        found_real_entities+=("$entity_id_from_config")
                    else
                        bashio::log.trace "Rule[${i}]   Entity from config list NOT FOUND in current states: ${entity_id_from_config}"
                        not_found_entities+=("$entity_id_from_config")
                    fi
                done # End while reading entity_ids from config json
                # Log results after the loop
                if [[ ${#found_real_entities[@]} -gt 0 ]]; then
                     bashio::log.notice "Rule[${i}] Real entities found based on optional config list: ${found_real_entities[*]}"
                fi
                if [[ ${#not_found_entities[@]} -gt 0 ]]; then
                     bashio::log.warning "Rule[${i}] Entities from optional config list NOT FOUND in current states: ${not_found_entities[*]}"
                fi
                # --- END Validation ---
             else
                 bashio::log.debug "Rule[${i}] Optional 'entities' list is present but empty or not an array."
             fi
        fi # End check for entities config existing

        # --- Log final processed values ---
        bashio::log.debug "Rule[${i}] Name: '${service_name}', Enabled: ${service_enabled}"
        bashio::log.debug "Rule[${i}] Service Type: ${service_type}, Port: ${service_port}"
        bashio::log.debug "Rule[${i}] IP Source: ${ip_source}, IP Attr: '${ip_attribute}'"
        bashio::log.debug "Rule[${i}] Name Source: ${name_source}, Name Attr: '${name_attribute}'"
        bashio::log.debug "Rule[${i}] State Filter: '${filter_state}', Inverse: ${filter_inverse}"
        bashio::log.debug "Rule[${i}] Filter Used: Integration='${ha_integration}', Domain='${ha_domain}', Pattern='${ha_entity_pattern}' (Default applied: ${use_default_pattern})"

        # --- Validation & Skip Checks ---
        if [[ "$service_enabled" != "true" ]]; then bashio::log.debug "Rule[${i}] Skipping disabled service."; continue; fi
        if [[ -z "$service_name" ]] || [[ -z "$service_type" ]] || [[ -z "$service_port" ]]; then bashio::log.warning "Rule[${i}] Required field missing (name, type, port). Skipping."; continue; fi
        if [[ "$ip_source" == "attribute" && -z "$ip_attribute" ]]; then bashio::log.warning "Rule[${i}] ip_source is 'attribute' but ip_attribute missing. Skipping."; continue; fi
        if [[ "$name_source" == "attribute" && -z "$name_attribute" ]]; then bashio::log.warning "Rule[${i}] name_source is 'attribute' but name_attribute missing. Skipping."; continue; fi

        # --- Construct JQ Filter ---
        bashio::log.info "[MARKER 1] Constructing filter..."
        jq_filter='.' # Start with all entities
        # Apply primary filter (using test() for pattern)
        if [[ -n "$ha_integration" ]]; then
            jq_filter+=" | select(.attributes.integration == \"${ha_integration}\")"
        elif [[ -n "$ha_domain" ]]; then
            jq_filter+=" | select(.entity_id | startswith(\"${ha_domain}.\"))"
        elif [[ -n "$ha_entity_pattern" ]]; then
            escaped_pattern=$(echo "$ha_entity_pattern" | sed -e 's/[.^$*+?(){}|[\]\\]/\\&/g' -e 's/\//\\\//g')
            jq_filter+=" | select(.entity_id | test(\"^${escaped_pattern}\"))"
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

            # Extract Name
            target_friendly_name=""
            if [[ "$name_source" == "entity_id" ]]; then
                target_friendly_name=$(jq -r '.entity_id' <<< "$entity_state_json")
            else # Default attribute
                target_friendly_name=$(jq -r ".attributes.\"${name_attribute}\" // .entity_id" <<< "$entity_state_json")
            fi

            # Debug and Trim Name
            bashio::log.debug "Name before trimming: '${target_friendly_name}'"
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

            # Extract IP
            entity_ip=""
            if [[ "$ip_source" == "state" ]]; then
                entity_ip=$(jq -r '.state' <<< "$entity_state_json")
            else # Default attribute
                entity_ip=$(jq -r ".attributes.\"${ip_attribute}\"" <<< "$entity_state_json")
            fi

            # Validation
            if [[ -z "$target_friendly_name" ]] || [[ "$target_friendly_name" == "null" ]]; then bashio::log.warning "Rule[${i}] Invalid name. JSON: ${entity_state_json}. Skip."; continue; fi
            if [[ -z "$entity_ip" ]] || [[ "$entity_ip" == "null" ]]; then bashio::log.warning "Rule[${i}] Invalid IP. JSON: ${entity_state_json}. Skip."; continue; fi
            if ! [[ "$entity_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then bashio::log.warning "Rule[${i}] Invalid IP format '${entity_ip}'. JSON: ${entity_state_json}. Skip."; continue; fi

            # Publish
            bashio::log.info "Rule[${i}] Publishing mDNS for '${target_friendly_name}' -> ${entity_ip}"
            publish_service "${IFACE}" "${target_friendly_name}" "${service_type}" "${service_port}" "${entity_ip}"

        done # End while loop processing filtered entities

        bashio::log.info "[MARKER 6] Reached end of FOR loop iteration for index ${i}."

    done # End of looping through service rules

    bashio::log.info "[MARKER 7] Exited FOR loop."
    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done # End while true