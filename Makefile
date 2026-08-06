.PHONY: test-server build start-server

test-server:
	SSL_CERT_FILE=$$(uv run python -c "import certifi; print(certifi.where())") uv run mapproxy-util serve-develop mapproxy.yaml

build:
	docker build --platform linux/amd64 -t hf-proxy-mapproxy .

start-server:
	docker compose up
