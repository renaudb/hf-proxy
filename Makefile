.PHONY: test-server

test-server:
	uv run mapproxy-util serve-develop mapproxy.yaml
