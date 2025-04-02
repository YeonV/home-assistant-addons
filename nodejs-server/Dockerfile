# Use an HA base image appropriate for Node.js (this one is minimal)
# Use ARG to get the architecture passed by the build process
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Explicitly install Node.js v18 ---
# Install specific Node.js v18 available in Alpine 3.18 repos for aarch64
# Check available versions: https://pkgs.alpinelinux.org/packages
RUN \
    echo "Updating apk cache..." \
    && apk update \
    && echo "Attempting to install nodejs 18.17.1..." \
    && apk add --no-cache \
        nodejs=18.17.1-r0 \
    && echo "Node.js installation command finished." \
    && echo "Verifying Node version:" \
    && node -v \
    && echo "Verifying NPM version:" \
    && npm -v \
    && echo "Node.js/npm installation and verification complete."
# --- End Node.js Installation ---

# Set the working directory
WORKDIR /usr/src/app

# Copy the prebuilt file and the run script
COPY bin.cjs .
COPY run.sh /

# Make run.sh executable
RUN chmod a+x /run.sh

# Expose the port (optional as host_network=true, but good practice)
EXPOSE 5000

# Tell S6 how to start your application via the run script
CMD [ "/run.sh" ]

# Set labels for HA compatibility (optional but good)
LABEL io.hass.version="VERSION" \
      io.hass.type="addon" \
      io.hass.arch="ARG_ARCH"