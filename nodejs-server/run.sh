#!/usr/bin/with-contenv bashio
# ^ Mandatory shebang for S6 overlay + bashio helpers

# Exit on errors
set -e

bashio::log.info "Starting Node.js cam-reverse server..."

# Execute your Node.js application
# Use "exec" to replace the shell process with the Node process
exec node /usr/src/app/bin.cjs http_server