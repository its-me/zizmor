ARG ZIZMOR_VERSION=latest
FROM ghcr.io/its-me/zizmor:${ZIZMOR_VERSION}

COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
