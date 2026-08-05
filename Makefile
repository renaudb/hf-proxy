.PHONY: test-server start-server

test-server:
	SSL_CERT_FILE=$$(uv run python -c "import certifi; print(certifi.where())") uv run mapproxy-util serve-develop mapproxy.yaml

start-server:
	docker compose up
