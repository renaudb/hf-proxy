---
name: add-wms-source
description: Add a new WMS layer to this MapProxy repo's mapproxy.yaml, given a WMS GetMap request URL (the kind you get by copying a "GetMap" link out of a GeoServer preview, QGIS, or a government geoportal like Quebec's MERN/SmartFaune services). Use this whenever the user pastes a URL containing REQUEST=GetMap&SERVICE=WMS (or just describes wanting to "add a WMS source", "proxy this WMS layer", or "cache this GeoServer layer") — even if they only give the URL with no further instructions. Handles parsing the URL, wiring up the source/cache/layer trio in mapproxy.yaml, validating against the live upstream server, and following this repo's git-worktree-per-change workflow.
---

# Add a WMS source to mapproxy.yaml

This repo runs MapProxy as a caching proxy in front of third-party WMS servers (mostly Quebec government geodata). Adding a new layer means turning one WMS `GetMap` URL into three linked entries in `mapproxy.yaml`: a `wms` source, a cache in front of it, and a layer that exposes the cache through the already-enabled demo/WMTS/TMS services.

Read `AGENTS.md` in the repo root first if you haven't — it points at the MapProxy docs and the two reference files (`full_example.yaml`, `full_seed_example.yaml`) for anything not covered here.

## 1. Parse the GetMap URL

The user will hand you something like:

```
https://servicesvecto3.mern.gouv.qc.ca/geoserver/SmartFaunePub/ows?REQUEST=GetMap&SERVICE=WMS&VERSION=1.3.0&FORMAT=image%2Fpng&STYLES=&TRANSPARENT=TRUE&LAYERS=Zone_chasse_da3_sefaq&WIDTH=1397&HEIGHT=1323&CRS=EPSG%3A3857&BBOX=...
```

Pull out:
- **Base endpoint** — everything before the `?`. This becomes `req.url` with a trailing `?` appended (matches the style already in the file, e.g. `.../ows?`).
- **LAYERS** — the layer name(s) requested. Usually one layer; if there are several, `layers:` can take a comma-separated list.
- **FORMAT** — becomes the cache's `format:` (e.g. `image/png`, `image/jpeg`). URL-decode it first (`image%2Fpng` → `image/png`).
- **VERSION** — becomes `wms_opts.version`. Default to `'1.3.0'` if missing.
- **TRANSPARENT** — becomes `req.transparent` (`true`/`false`, lowercase in YAML regardless of the URL's casing).
- **CRS** (or `SRS` on older WMS versions) — see the grid check below before assuming it's a non-issue.

**CRS check, don't skip this**: the repo's only grid is `webmercator` (`base: GLOBAL_WEBMERCATOR`, i.e. EPSG:3857). If `CRS=EPSG:3857`, you're fine — the source can be requested directly at the grid's native SRS with no reprojection. If the URL's CRS is anything else (EPSG:4326 is common for older govt WMS servers), MapProxy will need to reproject, which means adding `supported_srs` to the source and letting MapProxy do the conversion. Flag this to the user rather than silently assuming it'll just work — reprojected WMS sources are slower and occasionally produce edge artifacts, so it's worth a heads-up rather than a surprise.

## 2. Pick an identifier

Derive a short snake_case id from the LAYERS value — lowercase it, drop redundant/generic prefixes the source layer name carries (e.g. a GeoServer workspace name repeated in the layer name), keep it recognizable. Look at the existing `sources:`/`caches:`/`layers:` keys in `mapproxy.yaml` first: this repo's convention so far is a `qc_` prefix for Quebec government sources (`qc_imagerie`, `qc_zone_chasse`) — follow that pattern when the new source is from the same family, rather than inventing a new convention.

If the derived name is ambiguous or awkward (the source layer name is cryptic, e.g. `Zone_chasse_da3_sefaq`), propose your best guess and a short human-readable title, and let the user correct either before you commit — don't silently ship a name you're unsure about, since renaming later means updating three places plus the doc comments.

## 3. Wire up mapproxy.yaml

Add three entries, all keyed off `<id>`. This is the exact shape to match (adapt values, keep the style — 2-space indent, unquoted URLs, `version` quoted):

```yaml
layers:
  - name: <id>
    title: <Human readable title>
    sources: [<id>_cache]

caches:
  <id>_cache:
    grids: [webmercator]
    format: <format from FORMAT param>
    sources: [<id>_wms]

sources:
  <id>_wms:
    type: wms
    wms_opts:
      version: '<version from VERSION param>'
    req:
      url: <base endpoint>?
      layers: <LAYERS value>
      transparent: <true|false>
```

Append each block to the matching top-level section (`layers:`, `caches:`, `sources:`) rather than creating new sections — the file keeps all layers together, all caches together, etc.

**Don't add a `wms:` entry under `services:`.** This repo's convention (every source added so far) is to expose new layers only through the demo/WMTS/TMS services that are already enabled, with everything going through a cache — not to open a raw WMS passthrough. Leave `services:` alone unless the user explicitly asks for direct WMS passthrough.

## 4. Update the header doc comments

The top of `mapproxy.yaml` has a comment block listing example URLs per service, one line per existing layer. Add a matching line for the new layer under each service that serves it (WMTS, tiles, TMS), using the same `<id>` and an extension matching the cache format:

```
#     first tile: http://localhost:8080/wmts/<id>/webmercator/0/0/0.<ext>
```

## 5. Validate against the live server

Don't just check the YAML parses — confirm the actual upstream WMS responds through the proxy. This repo has a `make test-server` target and a `.claude/launch.json` entry named `mapproxy` that runs it, meant to be driven through `mcp__Claude_Browser__preview_start`.

**Gotcha**: `preview_start` reads `.claude/launch.json` from the *main repo root* (`/Users/renaudb/code/hf-proxy/.claude/launch.json`), not from the worktree you're actually working in — worktrees don't get their own copy consulted. That root-level file's `mapproxy` entry runs `make -C <absolute path> test-server`, hardcoded to whichever worktree last used it. Before you rely on it, check that path:

```bash
cat /Users/renaudb/code/hf-proxy/.claude/launch.json
```

If `runtimeArgs` points `-C` at a different worktree than the one you're editing, update it to your current worktree's path first — otherwise you'll start a server that silently serves someone else's (possibly stale) config, and you'll spend time debugging a "missing layer" that was never missing.

Then:
1. `preview_start({name: "mapproxy"})`.
2. `preview_logs` — check for a traceback (bad YAML, unknown option) right after startup.
3. Confirm the layer is registered: fetch `/demo/` (via `get_page_text` or `read_page`) and look for `<id>` in the WMTS/TMS layer tables.
4. Fetch a real tile to prove the upstream WMS actually answers, not just that the config parsed: `/tiles/<id>/webmercator/<z>/<x>/<y>.<ext>` (e.g. via `javascript_tool` running `fetch(...)`, or `curl` in Bash against `localhost:8080`). Confirm HTTP 200 and a `content-type` matching the configured format. A low zoom level (e.g. z=8) is enough — you're testing connectivity and config correctness, not coverage.
5. `preview_stop` the server once you've confirmed it.

If any step fails, the fix is almost always in the source block (wrong endpoint, wrong layer name, or a CRS mismatch per step 1) — re-check those before assuming it's a MapProxy quirk.

## 6. Git workflow

Follow `AGENTS.md`: work in a git worktree (`EnterWorktree`), branching from an up-to-date `main` (`git fetch && git checkout main && git pull` before creating the worktree). When the change is validated, commit, push, and open a PR — unless the user says otherwise for this particular change.
