#!/usr/bin/with-contenv bashio

# Exit on errors - keep this!
set -e

bashio::log.info "--- Simple run.sh: Starting up ---"
echo "--- Simple run.sh: Logging to stdout ---" # Also try stdout

# Keep the container alive for 5 minutes so we can see if it stays running
# If the container stays up, the problem is likely with executing the node app.
# If it still fails silently, the problem is more fundamental.
sleep 300

bashio::log.info "--- Simple run.sh: Finished sleeping (should only see this if testing sleep) ---"
echo "--- Simple run.sh: Finished sleeping ---"

# Comment out the real command for this test
# exec node /usr/src/app/bin.cjs http_server


# #!/usr/bin/with-contenv bashio
# # ^ Mandatory shebang for S6 overlay + bashio helpers

# # Exit on errors
# set -e

# bashio::log.info "Starting Node.js cam-reverse server..."

# # Execute your Node.js application
# # Use "exec" to replace the shell process with the Node process
# exec node /usr/src/app/bin.cjs http_server