FROM ghcr.io/mapproxy/mapproxy/mapproxy:1.16.0-nginx

RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY mapproxy.yaml /mapproxy/config/mapproxy.yaml
COPY logging.ini /mapproxy/config/logging.ini

VOLUME /mapproxy/config/cache_data
VOLUME /mapproxy/config/locks
VOLUME /mapproxy/config/tile_locks
