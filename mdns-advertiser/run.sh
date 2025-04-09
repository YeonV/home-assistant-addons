#!/usr/bin/with-contenv bashio

# ==============================================================================
# Script constants & Helper Functions (Keep as before)
# ==============================================================================
HA_API_URL="http://supervisor/core/api"
publish_service() { # ... same function as before ... # }

# ==============================================================================
# Main Script Logic
# ==============================================================================
bashio::log.info "Starting mDNS Advertiser..."

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

# --- NEW: Log test_device if provided ---
if bashio::config.exists 'test_device'; then
    TEST_DEVICE=$(bashio::config 'test_device')
    bashio::log.notice "Test Device selected in config: ${TEST_DEVICE}"
    # You can potentially query the device registry API later if needed, but just logging the ID for now.
fi
# --- END NEW ---

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
        local service_type; service_type=$(bashio::config "services[${i}].service_type")
        local service_port; service_port=$(bashio::config "services[${i}].service_port")
        local ip_source; ip_source=$(bashio::config "services[${i}].ip_source" "state") # Default state
        local ip_attribute; ip_attribute=$(bashio::config "services[${i}].ip_attribute")
        local name_source; name_source=$(bashio::config "services[${i}].name_source" "attribute") # Default attribute
        local name_attribute; name_attribute=$(bashio::config "services[${i}].name_attribute" "friendly_name")
        local filter_state; filter_state=$(bashio::config "services[${i}].filter_by_state")
        local filter_inverse_raw; filter_inverse_raw=$(bashio::config "services[${i}].filter_by_state_inverse")
        local filter_inverse; if [[ "$filter_inverse_raw" == "true" ]]; then filter_inverse="true"; else filter_inverse="false"; fi

        # --- NEW: Read optional filters and apply default ---
        local ha_integration; ha_integration=$(bashio::config "services[${i}].ha_integration")
        [[ "$ha_integration" == "null" ]] && ha_integration=""
        local ha_domain; ha_domain=$(bashio::config "services[${i}].ha_domain")
        [[ "$ha_domain" == "null" ]] && ha_domain=""
        local ha_entity_pattern; ha_entity_pattern=$(bashio::config "services[${i}].ha_entity_pattern")
        [[ "$ha_entity_pattern" == "null" ]] && ha_entity_pattern=""
        # Default pattern if no other filter specified
        local use_default_pattern=false
        if [[ -z "$ha_integration" && -z "$ha_domain" && -z "$ha_entity_pattern" ]]; then
            bashio::log.debug "Rule[${i}] No filter specified, using default pattern 'sensor.*_ip'."
            ha_entity_pattern="sensor.*_ip" # Apply default
            use_default_pattern=true
        fi
        # --- END NEW FILTER LOGIC ---

        # --- NEW: Log optional entities list if present ---
        if bashio::config.exists "services[${i}].entities"; then
            local entities_json; entities_json=$(bashio::config "services[${i}].entities")
             if echo "$entities_json" | jq -e '. | type == "array" and length > 0' > /dev/null; then
                bashio::log.notice "Rule[${i}] Optional 'entities' list provided in config (for logging only): ${entities_json}"
             else
                 bashio::log.debug "Rule[${i}] Optional 'entities' list is present but empty or not an array."
             fi
        fi
        # --- END NEW LOGGING ---

        bashio::log.debug "Rule[${i}] Name: '${service_name}', Enabled: ${service_enabled}"
        # ... (log other read configs) ...
        bashio::log.debug "Rule[${i}] Filter Used: Integration='${ha_integration}', Domain='${ha_domain}', Pattern='${ha_entity_pattern}' (Default applied: ${use_default_pattern})"


        # --- Validation & Skip Checks ---
        if [[ "$service_enabled" != "true" ]]; then bashio::log.debug "Rule[${i}] Skipping disabled service."; continue; fi
        if [[ -z "$service_name" ]] || [[ -z "$service_type" ]] || [[ -z "$service_port" ]]; then bashio::log.warning "Rule[${i}] Required field missing (name, type, port). Skipping."; continue; fi
        if [[ "$ip_source" == "attribute" && -z "$ip_attribute" ]]; then bashio::log.warning "Rule[${i}] ip_source is 'attribute' but ip_attribute missing. Skipping."; continue; fi
        if [[ "$name_source" == "attribute" && -z "$name_attribute" ]]; then bashio::log.warning "Rule[${i}] name_source is 'attribute' but name_attribute missing. Skipping."; continue; fi

        # --- Construct JQ Filter (using domain/pattern/integration) ---
        bashio::log.info "[MARKER 1] Constructing filter..."
        local jq_filter='.'
        if [[ -n "$ha_integration" ]]; then
            bashio::log.debug "Using filter: integration = ${ha_integration}"
            jq_filter+=" | select(.attributes.integration == \"${ha_integration}\")"
        elif [[ -n "$ha_domain" ]]; then
            bashio::log.debug "Using filter: domain = ${ha_domain}."
            jq_filter+=" | select(.entity_id | startswith(\"${ha_domain}.\"))"
        elif [[ -n "$ha_entity_pattern" ]]; then
            bashio::log.debug "Using filter: entity pattern = ${ha_entity_pattern}"
            local pattern_prefix="${ha_entity_pattern%\*}" # Remove trailing * for startswith
            jq_filter+=" | select(.entity_id | startswith(\"${pattern_prefix}\"))"
        # No 'else' needed because default pattern is applied above if all were empty
        fi

        # Add state filtering if configured
        if [[ -n "$filter_state" ]]; then
            bashio::log.debug "Adding state filter: state ${filter_inverse == true && echo '!= ' || echo '== '}'${filter_state}'"
            local op; if [[ "$filter_inverse" == "true" ]]; then op="!="; else op="=="; fi
            jq_filter+=" | select(.state ${op} \"${filter_state}\")"
        fi

        # Add the ip check (either state or attribute must not be null)
        if [[ "$ip_source" == "state" ]]; then
            jq_filter+=" | select(.state != null and .state != \"\" and .state != \"unknown\")" # Add basic state validation
        else
            jq_filter+=" | select(.attributes.\"${ip_attribute}\" != null)"
        fi
        bashio::log.debug "Constructed jq filter: ${jq_filter}"


        # --- Filter Entities from States ---
        bashio::log.info "[MARKER 2] Starting entity filtering..."
        local filtered_entities_json; filtered_entities_json=$(jq -c "[.[] | ${jq_filter}]" <<< "$states_json")
        local filter_exit_code=$?
        if [[ $filter_exit_code -ne 0 ]]; then bashio::log.error "JQ filtering failed (EC: ${filter_exit_code})!"; continue; fi
        if [[ "$(jq -c 'length == 0' <<< "$filtered_entities_json")" == "true" ]]; then bashio::log.info "Rule[${i}] No entities matched the filter."; continue; fi
        bashio::log.debug "Filtering successful. Found $(jq -c length <<< "$filtered_entities_json") entities."
        bashio::log.trace "Filtered entities sample: $(echo "$filtered_entities_json" | head -c 500)"

        # --- Process Each Filtered Entity ---
        bashio::log.info "[MARKER 4] Processing filtered entities..."
        echo "$filtered_entities_json" | jq -c '.[]' | while IFS= read -r entity_state_json; do
            bashio::log.trace "Rule[${i}] Processing filtered entity JSON: ${entity_state_json}"

            # --- Extract Name ---
            local target_friendly_name
            if [[ "$name_source" == "entity_id" ]]; then
                target_friendly_name=$(jq -r '.entity_id' <<< "$entity_state_json")
            else # Default to attribute
                target_friendly_name=$(jq -r ".attributes.\"${name_attribute}\" // .entity_id" <<< "$entity_state_json")
            fi

            # --- Extract IP ---
            local entity_ip
            if [[ "$ip_source" == "state" ]]; then
                entity_ip=$(jq -r '.state' <<< "$entity_state_json")
            else # Default to attribute
                entity_ip=$(jq -r ".attributes.\"${ip_attribute}\"" <<< "$entity_state_json")
            fi

            # --- Validate extracted values ---
            if [[ -z "$target_friendly_name" ]] || [[ "$target_friendly_name" == "null" ]]; then bashio::log.warning "Rule[${i}] Invalid name extracted. JSON: ${entity_state_json}. Skipping."; continue; fi
            if [[ -z "$entity_ip" ]] || [[ "$entity_ip" == "null" ]]; then bashio::log.warning "Rule[${i}] Invalid IP extracted. JSON: ${entity_state_json}. Skipping."; continue; fi
            if ! [[ "$entity_ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then bashio::log.warning "Rule[${i}] Extracted IP '${entity_ip}' invalid format. JSON: ${entity_state_json}. Skipping."; continue; fi

            # --- Publish ---
            bashio::log.info "Rule[${i}] Publishing mDNS for '${target_friendly_name}' -> ${entity_ip}"
            publish_service "${IFACE}" "${target_friendly_name}" "${service_type}" "${service_port}" "${entity_ip}" # TODO: TXT

        done # End while loop processing filtered entities

        bashio::log.info "[MARKER 6] Reached end of FOR loop iteration for index ${i}."

    done # End of looping through service rules

    bashio::log.info "[MARKER 7] Exited FOR loop."
    bashio::log.debug "Update cycle finished. Sleeping for ${UPDATE_INTERVAL} seconds."
    sleep "${UPDATE_INTERVAL}"
done # End while true