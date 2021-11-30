ARG BUILD_FROM=ghcr.io/hassio-addons/debian-base/amd64:5.2.2
# hadolint ignore=DL3006
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy Python requirements file
COPY requirements.txt /tmp/

# Setup base
ARG BUILD_ARCH=amd64
RUN \
    apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    alsa-utils \
    libasound2-plugins \
    cython3 \
    gcc \
    git \
    libatlas3-base \
    zlib1g-dev \
    portaudio19-dev \
    python3-dev \
    python3 \
    python3-pip \
    nginx \
    \
    # Pillow dependencies for dev branch
    libfreetype6-dev \
    libfribidi-dev \
    libharfbuzz-dev \
    libjpeg-turbo-progs \
    libjpeg62-turbo-dev \
    liblcms2-dev \
    libopenjp2-7-dev \
    tcl8.6-dev \
    tk8.6-dev \
    libtiff5-dev \
    \
    # aubio dependencies
    python3-aubio \
    aubio-tools \
    python3-numpy \
    libavcodec-dev \
    libavformat-dev \
    libavutil-dev \
    libswresample-dev \
    libavresample-dev \
    libsndfile1-dev \
    librubberband-dev \
    libsamplerate0-dev \
    && rm -fr \
    /var/{cache,log}/* \
    /var/lib/apt/lists/* \
    \
    && pip3 install \
    --no-cache-dir -r /tmp/requirements.txt \
    && pip3 install \
    --force-reinstall --no-cache-dir git+https://github.com/LedFx/LedFx@frontend_beta \
    && pip3 uninstall python-rtmidi -y \
    && pip3 install \ 
    --no-cache-dir python-rtmidi --install-option="--no-alsa" --install-option="--no-jack" \
    \
    #   && apk del --no-cache --purge .build-dependencies \
    && rm -fr \
    /etc/nginx \
    /root/.cache \
    /tmp/* \
    \
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/error.log

# Copy root filesystem
COPY rootfs /

# Build arguments
ARG BUILD_ARCH
ARG BUILD_DATE
ARG BUILD_DESCRIPTION
ARG BUILD_NAME
ARG BUILD_REF
ARG BUILD_REPOSITORY
ARG BUILD_VERSION

# Labels
LABEL \
    io.hass.name="${BUILD_NAME}" \
    io.hass.description="${BUILD_DESCRIPTION}" \
    io.hass.arch="${BUILD_ARCH}" \
    io.hass.type="addon" \
    io.hass.version=${BUILD_VERSION} \
    maintainer="Spiro C <spiroc@gmail.com>" \
    org.opencontainers.image.title="${BUILD_NAME}" \
    org.opencontainers.image.description="${BUILD_DESCRIPTION}" \
    org.opencontainers.image.vendor="Home Assistant Community Add-ons" \
    org.opencontainers.image.authors="Spiro C <spiroc@gmail.com>, Yeon <dev@yeonv.com>" \
    org.opencontainers.image.licenses="MIT" \
    org.opencontainers.image.url="https://addons.community" \
    org.opencontainers.image.source="https://github.com/${BUILD_REPOSITORY}" \
    org.opencontainers.image.documentation="https://github.com/${BUILD_REPOSITORY}/blob/main/README.md" \
    org.opencontainers.image.created=${BUILD_DATE} \
    org.opencontainers.image.revision=${BUILD_REF} \
    org.opencontainers.image.version=${BUILD_VERSION}
