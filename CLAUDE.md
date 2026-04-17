# CLAUDE.md — AI Agent Guide for antora-openehr

This file provides all the context an AI coding agent (Codex, Claude Code, Cursor, Junie, etc.) needs to work effectively with this repository.

---

## Project Overview

This is an **Antora-based documentation project** for openEHR specifications. It provides:

- An Antora playbook and local UI bundle to publish the openEHR specifications as a unified, multi-repository, multi-version documentation site.
- Migration scripts to reshape each specification repo from the old AsciiDoc structure into Antora modules.
- Validation helpers to keep repos consistent.

Key documentation files:
- `README.md` — high-level overview
- `START-HERE.md` — installation and setup
- `MIGRATION-GUIDE.md` — migration model, directory structure, and manual adjustments
- `QUICK-REFERENCE.md` — command cheat sheet

---

## Prerequisites

Choose **one** of:

- **Native path**: Node.js 18 LTS, npm, Git 2.0+, Make, Bash
- **Docker path** (recommended): Docker & Docker Compose — this is the primary tested environment, providing consistency across developers.

Windows users should use WSL2.

---

## Build & Run

### Docker Workflow (recommended)

```bash
docker compose up -d --build
docker compose exec antora bash
# Now run make commands inside the container
```

### Make Commands

```bash
# Full setup from scratch (wipe, install, branch, migrate, build, preview)
make all

# Development workflow
make install              # Install npm deps + clone specification repos into repos/
make create-all-branches  # Tags → release/*; master tip → development branch (Antora prerelease)
make migrate-all          # Migrate all repositories to Antora structure
make validate-all         # Validate all repositories
make build-local          # Build the site using antora-playbook-local.yml
make preview              # Start local server at http://localhost:8080

# Single-repo operations
make migrate-repo REPO=specifications-BASE
make validate-structure REPO=specifications-BASE
make create-branches REPO=specifications-BASE

# Maintenance
make update-repos         # git fetch --all on every cloned repo
make update-grammars      # Clone/update ANTLR grammar repos, copy .g4 files
make check-deps           # Verify node, npm, git are installed
make clean                # Remove build/ and .cache/
make clean-all            # Remove build/, .cache/, and repos/

# Production / CI
make build                # Build using production playbook
make ci-build             # install + build (CI target)

make help                 # List all available commands
```

The generated site output is in `build/`. Build log is written to `build.log` by `build-local`.

### Caddy Test Server

A Caddy reverse-proxy is available via Docker Compose profile `test`:

```bash
docker compose --profile test up caddy
# Serves build/ at http://localhost:8081
```

### Stop Docker

```bash
docker compose down
```

---

## Testing

There are **no automated tests**. Verification is manual:

1. Run `make build-local` and check for build errors (also review `build.log`).
2. Run `make preview` and inspect the generated HTML at `http://localhost:8080`.
3. Run `make validate-structure REPO=<repo>` to validate Antora directory structure.

---

## Directory Structure

```
antora-openehr/
├── antora-playbook.yml          # Production playbook
├── antora-playbook-local.yml    # Local dev playbook (primary for dev)
├── antora-playbook-github.yml   # GitHub-based playbook
├── package.json                 # Node.js dependencies
├── Dockerfile / docker-compose.yml
├── Makefile                     # Main automation
├── resources/
│   ├── global-vars.yml          # Global AsciiDoc attributes (loaded by extension)
│   ├── references.bib           # BibTeX bibliography for asciidoctor-bibtex
│   └── component_vars.adoc      # Component-level variable definitions
├── scripts/
│   ├── migration/               # Migration shell scripts (numbered 1–12)
│   │   └── main-migrate-repo.sh # Entry point: runs all migration steps
│   ├── create-release-branches.sh
│   └── validate-structure.sh
├── src/
│   ├── extensions/
│   │   └── load-global-vars.js  # Antora extension: loads global-vars.yml as attributes
│   ├── ui-bundle/               # Custom Antora UI bundle (Handlebars, CSS, JS)
│   ├── ui-bundle.zip            # Packaged UI bundle (referenced by playbook)
│   └── supplemental-ui/         # CSS overrides, images, HBS partial overrides
├── caddy/
│   └── Caddyfile                # Caddy config for test profile
├── repos/                       # Cloned specification repos (local builds)
├── examples/                    # Before/after structure samples
├── docs/                        # Placeholder for GitHub published docs
└── build/                       # Generated output (gitignored)
```

### Specification Repo Structure (after migration)

Each specification repo under `repos/` follows this Antora layout:

```
component-repo/
├── antora.yml              # Component descriptor (name, version, title, nav)
└── modules/
    ├── ROOT/               # Shared content (UML classes, diagrams)
    │   ├── pages/
    │   ├── partials/
    │   │   └── uml/classes/   # Shared UML class definitions
    │   └── images/
    │       └── uml/diagrams/  # Shared UML diagrams
    └── <module-name>/      # Each specification document (e.g. foundation_types)
        ├── nav.adoc
        ├── pages/
        ├── partials/
        └── images/
```

---

## Configuration Files

| File | Purpose |
|------|---------|
| `antora-playbook-local.yml` | Primary playbook for local dev. Defines content sources (local `repos/`) and UI bundle. |
| `antora-playbook.yml` | Production playbook |
| `antora-playbook-github.yml` | GitHub-based playbook |
| `antora.yml` (in each repo) | Component descriptor: name, version, title, nav |
| `resources/global-vars.yml` | Global AsciiDoc attributes injected by `load-global-vars.js` |
| `resources/references.bib` | BibTeX references for `asciidoctor-bibtex-js` |
| `package.json` | Node.js dependencies and scripts |

---

## Extensions & Plugins

The build pipeline uses several AsciiDoc/Antora extensions configured in the playbook:

| Extension | Purpose |
|-----------|---------|
| `load-global-vars.js` | Custom Antora extension that loads `resources/global-vars.yml` as AsciiDoc attributes with recursive interpolation |
| `@antora/lunr-extension` | Full-text search index generation |
| `asciidoctor-kroki` | Diagram rendering (PlantUML, ditaa, etc.) via Kroki |
| `@asciidoctor/tabs` | Tabbed content blocks in AsciiDoc |
| `@ayowel/asciidoctor-bibtex-js` | BibTeX citation support using `resources/references.bib` |

---

## Content Authoring — Code Style & Patterns

### AsciiDoc Conventions

Standard AsciiDoc with Antora extensions. Follow existing patterns in the codebase.

### File Naming

| Type | Convention | Example |
|------|-----------|---------|
| Pages | kebab-case.adoc | `foundation-types.adoc` |
| Partials | kebab-case.adoc | `primitive-types.adoc` |
| Images | kebab-case.ext | `class-diagram.svg` |
| Navigation | `nav.adoc` | `nav.adoc` |

### Migration Patterns (when editing migrated content)

- Use `xref:` instead of old internal links.
- Use `include::partial$name.adoc[]` for files in `partials/`.
- Reference UML from ROOT: `include::ROOT:partial$uml/classes/NAME.adoc[]`.
- Image from ROOT: `image::ROOT:uml/diagrams/diagram.svg[]`.

---

## Key Concepts

| Term | Meaning |
|------|---------|
| **Component** | A documentation unit (BASE, RM, AM, etc.) |
| **Module** | A section within a component (foundation_types, base_types, etc.) |
| **Version** | Git branch (master, release/1.0.3, etc.) |
| **Resource ID** | `[version@]component:module:family$path` |

---

## Gotchas

- **`load-global-vars.js` config key**: the playbook uses `var_files` (snake_case in YAML) which maps to `varFiles` in the extension code. Adding new global attribute files requires updating both the playbook and understanding the recursive interpolation logic.
- **ANTLR grammar files**: `.g4` files are copied from external repos (`adl-antlr`, `openEHR-antlr4`) into module `partials/` directories by `make update-grammars`. They are not checked into the spec repos — re-run after `make clone-repos` or `make migrate-all`.
- **UI bundle**: `src/ui-bundle.zip` is the packaged bundle referenced by the playbook. If you modify files in `src/ui-bundle/`, you must repackage the zip. `src/supplemental-ui/` overrides are applied on top and do NOT require repackaging.
- **Build log**: `make build-local` tees output to `build.log` at project root.
- **`runtime.fetch: true`** in the playbook allows Antora to fetch remote resources (e.g., Kroki diagrams). Builds require internet access.

---

## Specification Repositories

The project manages these openEHR specification repos (cloned into `repos/`):

`specifications-BASE`, `specifications-RM`, `specifications-AM`, `specifications-LANG`, `specifications-SM`, `specifications-QUERY`, `specifications-PROC`, `specifications-CDS`, `specifications-CNF`, `specifications-ITS-REST`, `specifications-ITS-JSON`, `specifications-ITS-XML`, `specifications-ITS-BMM`

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `antora.yml` not found | Run migration script for that repo |
| Images not showing | Update image paths to Antora format |
| Includes broken | Use `partial$` prefix |
| Build fails | Check `make validate-structure` output and `build.log` |
| npm install fails | Verify Node.js 18 LTS |
| Missing `.g4` files | Run `make update-grammars` |
| Global attributes not resolved | Check `resources/global-vars.yml` and extension log output |
