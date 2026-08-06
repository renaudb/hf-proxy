.PHONY: test-server build run

test-server:
	SSL_CERT_FILE=$$(uv run python -c "import certifi; print(certifi.where())") uv run mapproxy-util serve-develop mapproxy.yaml

build:
	docker build --platform linux/amd64 -t hf-proxy-mapproxy .

run:
	docker run --rm --platform linux/amd64 -p 8080:80 -v $$(pwd)/cache_data:/mapproxy/config/cache_data hf-proxy-mapproxy
