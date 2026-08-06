FROM ghcr.io/mapproxy/mapproxy/mapproxy:7.0.0-nginx

COPY mapproxy.yaml /mapproxy/config/mapproxy.yaml

VOLUME /mapproxy/config/cache_data
VOLUME /mapproxy/config/locks
VOLUME /mapproxy/config/tile_locks
