#!/usr/bin/with-contenv bashio
set -e

bashio::log.info "--- run.sh: Starting up ---"

# --- Attempt to get MQTT details using bashio::services ---
bashio::log.info "--- Querying MQTT service details via bashio ---"
MQTT_HOST_VAL=$(bashio::services mqtt "host") # Store raw value
MQTT_PORT_VAL=$(bashio::services mqtt "port")
MQTT_USER_VAL=$(bashio::services mqtt "username")
MQTT_PASS_VAL=$(bashio::services mqtt "password")

# --- Export variables IF bashio succeeded ---
# Check if the host query succeeded (bashio returns non-zero on failure)
# We assume if host works, the others likely did too, or will be empty strings.
if [[ $? -eq 0 && -n "${MQTT_HOST_VAL}" ]]; then
  bashio::log.info "Bashio query successful. Exporting MQTT details to environment..."
  export MQTT_HOST="${MQTT_HOST_VAL}"
  export MQTT_PORT="${MQTT_PORT_VAL}"
  export MQTT_USERNAME="${MQTT_USER_VAL}"
  export MQTT_PASSWORD="${MQTT_PASS_VAL}"

  # Log what was exported (carefully)
  bashio::log.info "Exported MQTT_HOST: ${MQTT_HOST}"
  bashio::log.info "Exported MQTT_PORT: ${MQTT_PORT}"
  bashio::log.info "Exported MQTT_USERNAME: ${MQTT_USERNAME}"
  if [[ -n "${MQTT_PASSWORD}" ]]; then
       bashio::log.info "Exported MQTT_PASSWORD: <set, length=${#MQTT_PASSWORD}>"
  else
       bashio::log.info "Exported MQTT_PASSWORD: <not set>"
  fi
else
  bashio::log.warning "Bashio query failed or MQTT host not found. Cannot export MQTT details."
fi
bashio::log.info "--- Finished querying/exporting MQTT service details ---"


# --- Optional: Dump environment AFTER exporting ---
# See if the exported variables appear here
bashio::log.info "--------------------- ENVIRONMENT VARIABLES (POST-EXPORT) START ---------------------"
env | sort
bashio::log.info "--------------------- ENVIRONMENT VARIABLES (POST-EXPORT) END -----------------------"
# --- End dump ---


# Optional: Sleep
# bashio::log.info "--- Sleeping for 2 seconds before starting Node ---"
# sleep 2


# Check node/script
APP_SCRIPT="/usr/src/app/bin.cjs"
 if ! command -v node &> /dev/null; then
    bashio::log.fatal "'node' command not found!"
    exit 1
fi
 if [ ! -f "${APP_SCRIPT}" ]; then
    bashio::log.fatal "Application script not found at ${APP_SCRIPT}"
    exit 1
fi
bashio::log.info "Node and script found. Node version: $(node -v)"

bashio::log.info "--- Attempting to execute Node.js application ---"

# Execute your Node.js application
# It will inherit variables exported above
exec node "${APP_SCRIPT}" http_server

bashio::log.warning "!!! exec command returned - Node app likely exited immediately !!!"
exit 1