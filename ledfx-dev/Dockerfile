ARG BUILD_FROM

FROM $BUILD_FROM

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Copy Python requirements file
COPY requirements.txt /tmp/

# Extra index for pre build armv7 python wheels

# Setup base
ARG BUILD_ARCH
RUN \
    apk add --no-cache --virtual .build-dependencies \
    build-base=0.5-r3 \
    ninja-build=1.11.1-r4\
    linux-headers=6.5-r0 \
    alsa-lib-dev=1.2.10-r0 \
    pkgconf=2.1.0-r0 \
    git=2.43.6-r0 \
    cmake=3.27.8-r0 \
    mbedtls-dev=2.28.9-r0 \
    && apk add --no-cache \
    alsa-plugins-pulse=1.2.7.1-r2 \
    nginx=1.24.0-r16 \
    mbedtls=2.28.9-r0 \
    portaudio-dev=19.7.0-r2 \
    pulseaudio-alsa=16.1-r11 \
    pulseaudio-utils=16.1-r11 \
    \
    && pip install \
    --no-cache-dir -r /tmp/requirements.txt \
    && pip install \
    --no-cache-dir git+https://github.com/LedFx/LedFx \
    \
    && rm -rf /usr/local/lib/python3.12/site-packages/ledfx_frontend \
    && curl -L --max-redirs 10 -o ledfx_frontend_hass.zip https://github.com/YeonV/LedFx-Frontend-v2/releases/latest/download/ledfx_frontend_hass.zip \
    && unzip ledfx_frontend_hass.zip && cp -r ledfx_frontend_hass /usr/local/lib/python3.12/site-packages/ledfx_frontend \
    \
    && find /usr/local/lib/python3.12/ -type d -name tests -depth -exec rm -rf {} \; \
    && find /usr/local/lib/python3.12/ -type d -name test -depth -exec rm -rf {} \; \
    && find /usr/local/lib/python3.12/ -name __pycache__ -depth -exec rm -rf {} \; \
    && find /usr/local/lib/python3.12/ -name "*.pyc" -depth -exec rm -f {} \; \
    \
    # Remove not needed packages
    && apk del --no-cache --purge .build-dependencies \
    && rm -fr \
    /ledfx_frontend_hass* \
    /etc/nginx \
    /root/.cache \
    /tmp/* \
    && find /tmp/ -mindepth 1  -delete \
    && mkdir -p /var/log/nginx \
    && touch /var/log/nginx/error.log 
# Copy root filesystem
COPY rootfs /
