# Use an HA base image appropriate for Node.js (this one is minimal)
# Use ARG to get the architecture passed by the build process
ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# --- Remove Node.js/npm installation ---
# The base image should already contain a suitable Node.js version (likely v20)
# RUN \
#    apk add --no-cache \
#        nodejs=... \
#        npm=...

# --- Verification Step (Recommended) ---
# Add this to verify the Node/npm versions present in the base image during build
RUN \
    echo "Verifying Node.js and npm versions from base image:" \
    && echo "Node version:" \
    && node -v \
    && echo "NPM version:" \
    && npm -v \
    && echo "Verification complete."
# --- End Verification Step ---


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