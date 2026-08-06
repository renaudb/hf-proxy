FROM ghcr.io/mapproxy/mapproxy/mapproxy:1.16.0-nginx

COPY mapproxy.yaml /mapproxy/config/mapproxy.yaml

VOLUME /mapproxy/config/cache_data
