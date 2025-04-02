#!/usr/bin/with-contenv bashio mqtt

# # Just log a message and wait, doing nothing else
# bashio::log.info "--- MINIMAL run.sh: Container started, attempting sleep ---"
# sleep 3600 # Sleep for an hour to keep the container running
# bashio::log.info "--- MINIMAL run.sh: Sleep finished (shouldn't normally reach here) ---"
# exit 0

# # #!/usr/bin/with-contenv bashio
# IMPORTANT: Temporarily COMMENT OUT set -e to allow logging even if commands fail
# set -e

# === VERY FIRST STEP: Try plain echo to stdout ===
echo "--- run.sh: TOP OF SCRIPT REACHED (stdout) ---"

# === SECOND STEP: Try bashio logging immediately ===
bashio::log.info "--- run.sh: TESTING BASHIO LOGGING ---" || echo "--- run.sh: bashio::log.info FAILED (stdout) ---"

# === THIRD STEP: Check bashio::services availability ===
bashio::log.info "--- run.sh: Checking bashio::services availability ---"
if command -v bashio::services &> /dev/null; then
    bashio::log.info "--- run.sh: bashio::services command seems available ---"
else
    bashio::log.error "--- run.sh: bashio::services command NOT FOUND ---"
    # Maybe exit here, or continue to see if env vars exist anyway
fi

# === FOURTH STEP: Attempt MQTT query, log exit code immediately ===
bashio::log.info "--- run.sh: Attempting MQTT host query ---"
MQTT_HOST_VAL=$(bashio::services mqtt "host")
HOST_EXIT_CODE=$? # Capture exit code *immediately*
bashio::log.info "--- run.sh: MQTT host query finished. Exit Code=[${HOST_EXIT_CODE}]. Value=[${MQTT_HOST_VAL}] ---"

# === FIFTH STEP: Decide whether to export based on query result ===
if [[ ${HOST_EXIT_CODE} -eq 0 && -n "${MQTT_HOST_VAL}" ]]; then
    bashio::log.info "--- run.sh: Bashio host query succeeded. Attempting export... ---"
    export MQTT_HOST="${MQTT_HOST_VAL}"
    MQTT_PORT_VAL=$(bashio::services mqtt "port") # Get others only if host succeeded
    MQTT_USER_VAL=$(bashio::services mqtt "username")
    MQTT_PASS_VAL=$(bashio::services mqtt "password")
    export MQTT_PORT="${MQTT_PORT_VAL}"
    export MQTT_USERNAME="${MQTT_USER_VAL}"
    export MQTT_PASSWORD="${MQTT_PASS_VAL}"
    bashio::log.info "--- run.sh: Export commands executed. ---"
else
    bashio::log.warning "--- run.sh: Bashio host query failed (Code: ${HOST_EXIT_CODE}) or host value empty. Skipping export. ---"
fi

# === SIXTH STEP: Dump environment to see results ===
bashio::log.info "--- run.sh: Dumping environment post-query/export ---"
bashio::log.info "--------------------- ENVIRONMENT VARIABLES START ---------------------"
env | sort
bashio::log.info "--------------------- ENVIRONMENT VARIABLES END -----------------------"

# === SEVENTH STEP: Check Node installation ===
bashio::log.info "--- run.sh: Checking node ---"
if ! command -v node &> /dev/null; then
    bashio::log.fatal "--- run.sh: 'node' command not found! EXITING ---"
    exit 1
fi
bashio::log.info "--- run.sh: Node found: $(command -v node). Version: $(node -v) ---"

# === EIGHTH STEP: Check script file ===
bashio::log.info "--- run.sh: Checking script file ---"
APP_SCRIPT="/usr/src/app/bin.cjs"
if [ ! -f "${APP_SCRIPT}" ]; then
    bashio::log.fatal "--- run.sh: Application script not found: ${APP_SCRIPT}. EXITING ---"
    exit 1
fi
bashio::log.info "--- run.sh: Script file found: ${APP_SCRIPT} ---"

# === FINAL STEP: Execute Node ===
bashio::log.info "--- run.sh: Attempting 'exec node ${APP_SCRIPT} http_server' ---"
exec node "${APP_SCRIPT}" http_server

# === Fallback: Should not be reached ===
bashio::log.error "--- run.sh: !!! EXEC NODE RETURNED OR FAILED !!! EXITING ---"
exit 1