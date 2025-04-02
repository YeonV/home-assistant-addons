# Use an HA base image appropriate for Node.js (this one is minimal)
# Use ARG to get the architecture passed by the build process
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Set the working directory
WORKDIR /usr/src/app

# Install Node.js (example uses v18 - adjust if needed)
# Check available versions: https://github.com/nodesource/distributions?tab=readme-ov-file#debinstall
RUN \
    apk add --no-cache \
        nodejs=18.20.4-r0 \
        npm=10.8.2-r0 \
    && npm install -g npm@10.8.2

# Copy the prebuilt file and the run script
COPY bin.cjs .
COPY run.sh /

# Make run.sh executable (redundant if done via Git/locally, but safe)
RUN chmod a+x /run.sh

# Expose the port (optional as host_network=true, but good practice)
EXPOSE 5000

# Tell S6 how to start your application via the run script
# This CMD is NOT run directly by Docker, but interpreted by S6
CMD [ "/run.sh" ]

# Set labels for HA compatibility (optional but good)
LABEL io.hass.version="VERSION" \
      io.hass.type="addon" \
      io.hass.arch="ARG_ARCH"