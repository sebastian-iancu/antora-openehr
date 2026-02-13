# AGENTS.md — AI Agent Guide for antora-openehr

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
- **Docker path** (recommended): Docker & Docker Compose

Windows users should use WSL2.

---

## Build & Run

### Docker Workflow (recommended)

```bash
docker compose up -d --build
docker compose exec antora bash
# Now run make commands inside the container
```

### Common Make Commands

```bash
make install              # Install npm deps + clone specification repos into repos/
make create-all-branches  # Convert tags (e.g. Release-1.0.3) to release branches
make migrate-repo REPO=specifications-BASE   # Migrate a single repo
make validate-structure REPO=specifications-BASE  # Validate structure
make migrate-all          # Migrate all repositories
make validate-all         # Validate all repositories
make build-local          # Build the site using antora-playbook-local.yml
make preview              # Start local server at http://localhost:8080
make help                 # List all available commands
```

The generated site output is in `build/site/`.

### Stop Docker

```bash
docker compose down
```

---

## Testing

There are **no automated tests**. Verification is manual:

1. Run `make build-local` and check for build errors.
2. Run `make preview` and inspect the generated HTML at `http://localhost:8080`.
3. Run `make validate-structure REPO=<repo>` to validate Antora directory structure.

---

## Directory Structure

```
antora-openehr/
├── antora-playbook.yml          # Production playbook
├── antora-playbook-local.yml    # Local development playbook (primary for dev)
├── antora-playbook-github.yml   # GitHub-based playbook
├── package.json                 # Node.js dependencies
├── Dockerfile / docker-compose.yml
├── Makefile                     # Main automation
├── scripts/
│   ├── migration/               # Migration shell scripts (numbered steps)
│   └── ...                      # Validation, branch creation helpers
├── src/
│   ├── extensions/
│   │   └── load-global-vars.js  # Antora extension
│   └── supplemental-ui/         # CSS, images, Handlebars partials
├── repos/                       # Cloned specification repos (local builds)
├── examples/                    # Before/after structure samples
├── docs/                        # Placeholder for GitHub published docs    
└── build/site/                  # Generated output (gitignored)
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
| `package.json` | Node.js dependencies and scripts |

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

### Antora Resource ID Format

`[version@]component:module:family$relative-path`

### Include Directives

```asciidoc
// Partial in same module
include::partial$filename.adoc[]

// Partial in ROOT module
include::ROOT:partial$path/filename.adoc[]

// Example file
include::example$code.java[]
```

### Image References

```asciidoc
// Image in same module
image::diagrams/diagram.svg[]

// Image in ROOT module
image::ROOT:uml/diagrams/diagram.svg[]
```

### Cross References

```asciidoc
// Within same page
<<_section_anchor>>

// To another page in same module
xref:other-page.adoc[Link text]

// To another module in same component
xref:other-module:page.adoc[Link text]

// To another component
xref:RM:ehr:index.adoc[EHR in RM]

// To specific version
xref:1.0.3@RM:ehr:index.adoc[EHR in RM 1.0.3]
```

### Migration Patterns (when editing migrated content)

- Use `xref:` instead of old internal links.
- Use `include::partial$name.adoc[]` for files in `partials/`.
- Reference UML from ROOT: `include::ROOT:partial$uml/classes/NAME.adoc[]`.

---

## Key Concepts

| Term | Meaning |
|------|---------|
| **Component** | A documentation unit (BASE, RM, AM, etc.) |
| **Module** | A section within a component (foundation_types, base_types, etc.) |
| **Version** | Git branch (master, release/1.0.3, etc.) |
| **Resource ID** | `[version@]component:module:family$path` |

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `antora.yml` not found | Run migration script for that repo |
| Images not showing | Update image paths to Antora format |
| Includes broken | Use `partial$` prefix |
| Build fails | Check `make validate-structure` output |
| npm install fails | Verify Node.js 18 LTS |
| Command not found | Ensure you're in project root with `make` installed |

---

## Useful Links

- Antora Docs: https://docs.antora.org
- AsciiDoc Syntax: https://docs.asciidoctor.org
- openEHR Specs: https://specifications.openehr.org
- GitHub Issues: https://github.com/sebastian-iancu/antora-openehr/issues
