# AGENTS.md

This project runs [MapProxy](https://mapproxy.org/), a proxy/caching server for WMS/WMTS/TMS/KML map tile services.

- When working on `mapproxy.yaml`, `seed.yaml`, or any MapProxy configuration/behavior questions, consult the official documentation at https://mapproxy.github.io/mapproxy/latest/ before guessing at options or syntax.
- `full_example.yaml` and `full_seed_example.yaml` are MapProxy's own reference files documenting all available config and seed options — check them alongside the docs.
- Use `make test-server` to start the local MapProxy development server (serves `mapproxy.yaml` on http://localhost:8080) rather than invoking `mapproxy-util` directly.
