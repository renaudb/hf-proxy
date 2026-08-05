.PHONY: test-server docker-server

test-server:
	SSL_CERT_FILE=$$(uv run python -c "import certifi; print(certifi.where())") uv run mapproxy-util serve-develop mapproxy.yaml

docker-server:
	docker compose up
