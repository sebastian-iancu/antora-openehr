# openEHR Specifications — Antora Migration Project

[![Antora](https://img.shields.io/badge/Antora-3.1-blue)]()

This repository provides the structure and tools to migrate the openEHR specifications to Antora and to build a unified, multi‑repository, multi‑version documentation site.

Use this README for a high‑level overview. For setup and commands, start with `START-HERE.md`.

## What this project is

- A coherent Antora playbook and UI to publish the openEHR specifications
- A migration approach that reshapes each specification repo into Antora modules
- A set of helper scripts and validations to keep repos consistent
- A build layout that supports both local and containerized workflows

Why Antora:
- Supports multiple versions via Git branches
- Keeps components in separate repositories but builds one cohesive site
- Enables clean cross‑referencing across components and versions

## What’s in this repo

- `antora-playbook*.yml` — Antora configuration for production and local builds
- `supplemental-ui/` — UI extensions (CSS, partials, shared images)
- `scripts/` — migration and validation helpers
- `examples/` — before/after structure samples
- `repos/` — the place where specification repos are cloned for local builds

See `QUICK-REFERENCE.md` for a concise command cheat sheet and `MIGRATION-GUIDE.md` for details of the migration model and structure.

## Who should read what

- New contributors: start with `START-HERE.md` (installation and how to run)
- Editors/authors: see `MIGRATION-GUIDE.md` (how content is organized in Antora)
- Operators: see `QUICK-REFERENCE.md` (frequent commands)

## Directory Structure Overview

```
antora-openehr-migration/
├── 📄 Configuration
│   ├── antora-playbook.yml
│   ├── antora-playbook-local.yml
│   ├── package.json
│   ├── Dockerfile
│   └── docker-compose.yml
│
├── 🛠️ Build Tools
│   ├── Makefile (main automation)
│   └── scripts/
│       ├── migrate/
│       │   └── *.sh
│       ├── create-release-branches.sh
│       └── validate-structure.sh
│
├── 🎨 Customization
│   └── supplemental-ui/
│       ├── css/
│       ├── img/
│       └── partials/
│
├── 📚 Documentation
│   ├── README.md
│   ├── MIGRATION-GUIDE.md
│   ├── QUICK-REFERENCE.md
│   └── CHANGELOG.md
│
└── 💡 Examples
    ├── before/STRUCTURE.md
    └── after/STRUCTURE.md
```
---

## Links

- Start here: `START-HERE.md`
- Migration model: `MIGRATION-GUIDE.md`
- Commands cheat sheet: `QUICK-REFERENCE.md`
- Changelog: `CHANGELOG.md`
- Antora docs: https://docs.antora.org

—

Status: Active Development
