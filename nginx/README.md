# Nginx Legacy URL Redirects

## What this does

The old `specifications.openehr.org` served specs as single-page HTML files:
```
/releases/AM/2.2.0/AOM2.html
```

The new Antora-based site uses a different structure:
```
/AM/Release-2.2.0/AOM2/
```

`legacy-redirects.conf` is an nginx config that handles this rewrite with 301 permanent redirects.

## Files

- `legacy-redirects.conf` — production nginx config, include this in the server block
- `nginx.conf` — test nginx server config wrapping the above
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

Include `legacy-redirects.conf` inside the nginx `server {}` block:

```nginx
include /path/to/legacy-redirects.conf;
```

## Testing

Requires Docker and a completed build in `build/` — run `make build` first.

```bash
# Start nginx
docker compose --profile test up nginx

# In another terminal
./nginx/test-redirects.sh
```

Each test first checks whether the old URL actually exists on the live `specifications.openehr.org` site. If it does not, the test is skipped. Only URLs confirmed to exist on the live site are tested against the local nginx redirect.

The test suite covers:
- All components with `latest` and `development` versions
- All release versions found in the specification repos (AM, BASE, RM, LANG, PROC, QUERY, ITS-REST)

## What is not handled

Anchor fragments (`#_some_section`) are browser-only — they are never sent to the server and cannot be redirected. After the 301, the browser will attempt the anchor on the new page. If the content was reorganised into sub-pages (which it was), the anchor silently fails and the user lands at the top of the module index. This is an accepted limitation.
