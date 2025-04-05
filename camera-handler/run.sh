#!/usr/bin/with-contenv bashio

# === Log Start ===
bashio::log.info "--- run.sh: Starting Camera Handler Addon v$(bashio::addon.version) ---"

# === Read Addon Options using bashio ===
MQTT_ENABLED=$(bashio::config.true 'mqtt') # Returns true/false strings
UI_PORT=$(bashio::config 'ui_port')
LOG_LEVEL=$(bashio::config 'log_level')

# Validate port or set default if invalid/missing
if ! bashio::var.is_port "${UI_PORT}"; then
    bashio::log.warning "Invalid UI Port specified (${UI_PORT}). Using default 5000."
    UI_PORT=5000
fi

# Validate log level or set default
if ! bashio::var.equals "${LOG_LEVEL}" "debug" && \
   ! bashio::var.equals "${LOG_LEVEL}" "info" && \
   ! bashio::var.equals "${LOG_LEVEL}" "warning" && \
   ! bashio::var.equals "${LOG_LEVEL}" "error" && \
   ! bashio::var.equals "${LOG_LEVEL}" "trace"; then # Assuming your logger supports trace
    bashio::log.warning "Invalid Log Level specified (${LOG_LEVEL}). Using default 'info'."
    LOG_LEVEL="info"
fi

bashio::log.info "--- run.sh: Addon Options ---"
bashio::log.info "MQTT Discovery Enabled: ${MQTT_ENABLED}"
bashio::log.info "Using UI Port: ${UI_PORT}"
bashio::log.info "Log Level Set To: ${LOG_LEVEL}"

# === Export Options as Environment Variables for Node.js ===
export ADDON_MQTT_ENABLED="${MQTT_ENABLED}"
export ADDON_UI_PORT="${UI_PORT}"
export ADDON_LOG_LEVEL="${LOG_LEVEL}" # Export log level
bashio::log.info "--- run.sh: Exported options to environment ---"

# === Check bashio::services availability (Good Practice) ===
if ! command -v bashio::services &> /dev/null; then
    bashio::log.error "--- run.sh: bashio::services command NOT FOUND. MQTT checks might fail. ---"
fi

# === MQTT Credentials (Only if MQTT service is available) ===
# Fetch credentials, Node.js decides *if* to use them
if bashio::services.available "mqtt"; then
    bashio::log.info "--- run.sh: MQTT service is available. Reading credentials... ---"
    MQTT_HOST_VAL=$(bashio::services mqtt "host")
    HOST_EXIT_CODE=$?
    if [[ ${HOST_EXIT_CODE} -eq 0 && -n "${MQTT_HOST_VAL}" ]]; then
        bashio::log.info "--- run.sh: Exporting MQTT credentials... ---"
        export MQTT_HOST="${MQTT_HOST_VAL}"
        export MQTT_PORT=$(bashio::services mqtt "port")
        export MQTT_USERNAME=$(bashio::services mqtt "username")
        export MQTT_PASSWORD=$(bashio::services mqtt "password")
    else
        bashio::log.warning "--- run.sh: Failed to get MQTT host (Code: ${HOST_EXIT_CODE}). Credentials *not* exported. ---"
    fi
else
    bashio::log.warning "--- run.sh: MQTT service is NOT available via bashio. Credentials *not* exported. ---"
fi

# === Node/Script Checks ===
bashio::log.info "--- run.sh: Checking node ---"
if ! command -v node &> /dev/null; then
    bashio::log.fatal "--- run.sh: 'node' command not found! EXITING ---"; exit 1;
fi
bashio::log.info "--- run.sh: Node found: $(command -v node). Version: $(node -v) ---"

bashio::log.info "--- run.sh: Checking script file ---"
APP_SCRIPT="/usr/src/app/bin.cjs" # Assuming bin.cjs is your entry point
if [ ! -f "${APP_SCRIPT}" ]; then
    bashio::log.fatal "--- run.sh: Application script not found: ${APP_SCRIPT}. EXITING ---"; exit 1;
fi
bashio::log.info "--- run.sh: Script file found: ${APP_SCRIPT} ---"

# === Execute Node ===
bashio::log.info "--- run.sh: Attempting 'exec node ${APP_SCRIPT} http_server' ---"
# The first argument 'http_server' might be specific to your bin.cjs, adjust if needed
exec node "${APP_SCRIPT}" http_server

bashio::log.error "--- run.sh: !!! EXEC NODE RETURNED OR FAILED !!! EXITING ---"
exit 1