ARG BUILD_FROM
FROM ${BUILD_FROM}

# Add needed packages
# avahi-utils provides avahi-publish
# curl is needed to query HA API
# jq is needed to parse JSON response
RUN apk add --no-cache \
    bash \
    avahi \
    curl \
    jq \
    coreutils \
    busybox-extras

# Copy run script
COPY run.sh /
RUN chmod a+x /run.sh

CMD [ "/run.sh" ]