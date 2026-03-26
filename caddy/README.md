# Caddy Legacy URL Redirects

## What this does

The old `specifications.openehr.org` served specs as single-page HTML files:
```
/releases/AM/2.2.0/AOM2.html
```

The new Antora-based site uses a different structure:
```
/AM/Release-2.2.0/AOM2/
```

`Caddyfile` handles this rewrite with 301 permanent redirects and serves the static build output.

## Files

- `Caddyfile` — Caddy server config with redirect rules and static file serving
- `test-redirects.sh` — curl-based test script
- `README.md` — this file

## Version handling

| Old URL segment | New URL segment | Example |
|---|---|---|
| `2.2.0` | `Release-2.2.0` | bare numeric → prefixed |
| `Release-1.0.3` | `Release-1.0.3` | already prefixed → unchanged |
| `latest` | `latest` | named → unchanged |
| `development` | `development` | named → unchanged |

## Production usage

The `Caddyfile` is self-contained. Mount it and the build output:

```bash
docker run -p 80:80 \
  -v ./build:/srv:ro \
  -v ./caddy/Caddyfile:/etc/caddy/Caddyfile:ro \
  caddy:alpine
```

## Testing

Requires Docker and a completed build in `build/` — run `make build-local` first.

```bash
# Start Caddy
docker compose --profile test up caddy

# In another terminal
./caddy/test-redirects.sh
```

Each test first checks whether the old URL actually exists on the live `specifications.openehr.org` site. If it does not, the test is skipped. Only URLs confirmed to exist on the live site are tested against the local Caddy redirect.

## What is not handled

Anchor fragments (`#_some_section`) are browser-only — they are never sent to the server and cannot be redirected. After the 301, the browser will attempt the anchor on the new page. If the content was reorganised into sub-pages (which it was), the anchor silently fails and the user lands at the top of the module index. This is an accepted limitation.
