# openEHR Specifications - Antora Migration Guide

## Table of Contents

1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Directory Structure](#directory-structure)
4. [Migration Process](#migration-process)
5. [Manual Adjustments](#manual-adjustments)
6. [Building and Testing](#building-and-testing)
7. [Troubleshooting](#troubleshooting)
8. [Appendices](#appendices)

---

## Overview

This guide provides step-by-step instructions for migrating openEHR specification repositories from the current AsciiDoc structure to Antora-based documentation system.

### What is Antora?

Antora is a multi-repository documentation site generator for AsciiDoc. It's designed for:
- Managing documentation across multiple Git repositories
- Supporting multiple versions of documentation
- Creating component-based documentation sites
- Building static HTML sites that can be hosted anywhere

### Migration Goals

- Maintain current content with minimal changes
- Enable multi-version documentation (Release-1.0.2, 1.0.3, etc.)
- Keep each specification component in its own repository
- Preserve UML diagrams and class definitions
- Maintain cross-references between components

---

## Prerequisites

### Required Software

- **Git** (2.0 or higher)
- **Node.js** (16.0 or higher) and npm
- **Make** (for using Makefile commands)
- **Bash** (for running migration scripts)

### Optional Software

- **Docker** and **Docker Compose** (for containerized builds)
- **Python 3** (for local preview server)

### Installation

#### Option 1: Native Installation

```bash
# Install Node.js and npm (example for Ubuntu/Debian)
curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Make
sudo apt-get install make

# Verify installations
node --version
npm --version
make --version
```

#### Option 2: Docker Installation

```bash
# Install Docker and Docker Compose
# Follow instructions at: https://docs.docker.com/get-docker/

# Verify installation
docker --version
docker-compose --version
```

---

## Directory Structure

### Before Migration (Current Structure)

```
specifications-BASE/
├── docs/
│   ├── foundation_types/
│   │   ├── master.adoc
│   │   ├── master01-preface.adoc
│   │   ├── master02-overview.adoc
│   │   ├── master03-types.adoc
│   │   └── images/
│   ├── base_types/
│   │   └── ...
│   └── UML/
│       ├── classes/
│       │   ├── LOCATABLE.adoc
│       │   └── ...
│       └── diagrams/
│           └── ...
├── computable/
└── README.adoc
```

### After Migration (Antora Structure)

```
specifications-BASE/
├── antora.yml                      # Component descriptor
├── modules/
│   ├── ROOT/                       # Root module (shared content)
│   │   ├── pages/
│   │   │   └── index.adoc          # Component landing page
│   │   ├── partials/
│   │   │   └── uml/
│   │   │       └── classes/        # UML class definitions
│   │   ├── images/
│   │   │   └── uml/
│   │   │       └── diagrams/       # UML diagrams
│   │   └── nav.adoc                # Root navigation
│   ├── foundation_types/           # Module (was docs/foundation_types)
│   │   ├── pages/
│   │   │   └── index.adoc          # Was master.adoc
│   │   ├── partials/
│   │   │   ├── preface.adoc        # Was master01-preface.adoc
│   │   │   ├── overview.adoc       # Was master02-overview.adoc
│   │   │   └── types.adoc          # Was master03-types.adoc
│   │   ├── images/
│   │   └── nav.adoc
│   └── base_types/
│       └── ...
├── computable/                     # Unchanged
└── README.adoc                     # Unchanged
```

---

## Migration Process

### Step 1: Set Up Build Repository

Clone or create the `openehr-antora` build repository:

```bash
git clone <url-to-openehr-antora-repo>
cd openehr-antora
```

### Step 2: Install Dependencies

#### Using Native Installation

```bash
npm install
```

#### Using Docker

```bash
make docker-build
```

### Step 3: Clone Specification Repositories

```bash
# Clone all specification repositories
make clone-repos

# This creates a repos/ directory with all components:
# repos/
#   ├── specifications-BASE/
#   ├── specifications-RM/
#   ├── specifications-AM/
#   └── ...
```

### Step 4: Create Release Branches

Convert existing git tags to release branches:

```bash
# For a single repository
make create-branches REPO=specifications-BASE

# For all repositories
make create-all-branches
```

This creates branches like:
- `release/1.0.2` from tag `Release-1.0.2`
- `release/1.0.3` from tag `Release-1.0.3`
- etc.

### Step 5: Test Migration (Dry Run)

Before making changes, test the migration:

```bash
cd repos/specifications-BASE
../../scripts/migrate-repo.sh . dry-run
```

Review the output to understand what changes will be made.

### Step 6: Migrate Repository Structure

```bash
# Migrate a single repository
make migrate-repo REPO=specifications-BASE

# Or migrate all repositories
make migrate-all
```

### Step 7: Validate Structure

```bash
# Validate a single repository
make validate-structure REPO=specifications-BASE

# Or validate all repositories
make validate-all
```

### Step 8: Manual Adjustments

**IMPORTANT:** The migration script handles directory restructuring, but you must manually update AsciiDoc content. See the [Manual Adjustments](#manual-adjustments) section below.

### Step 9: Build and Test

```bash
# Build from local repositories
make build-local

# Preview the site
make preview
# Opens http://localhost:8080
```

---

## Manual Adjustments

After running the migration script, you **must** manually update the following in your AsciiDoc files:

### 1. Update Include Directives for Partials

**Before (in old master.adoc):**
```asciidoc
include::master01-preface.adoc[]
include::master02-overview.adoc[]
include::master03-types.adoc[]
```

**After (in modules/foundation_types/pages/index.adoc):**
```asciidoc
//
// --------------------------------------------- CHAPTERS -----------------------------------------------
//
== Contents

:sectnums:
. xref:preface.adoc
. xref:overview.adoc
. xref:types.adoc
```

**Pattern:** xref to a page in the same module.

### 2. Update UML Class Includes

**Before:**
```asciidoc
include::{uml_export_dir}/classes/pathable.adoc[]
include::{uml_export_dir}/classes/locatable.adoc[]
include::{uml_export_dir}/classes/archetypes.adoc[]
```

**After:**
```asciidoc
include::ROOT:partial$uml/classes/pathable.adoc[]
include::ROOT:partial$uml/classes/locatable.adoc[]
include::ROOT:partial$uml/classes/archetypes.adoc[]
```

**Pattern:** `ROOT:partial$` for content in the ROOT module's partials.

### 3. Update Image References

**Before:**
```asciidoc
image::{diagrams_uri}/foundation-types.svg[]
image::{uml_diagrams_uri}/BASE-classes.svg[]
```

**After (for images in same module):**
```asciidoc
image::diagrams/foundation-types.svg[]
```

**After (for UML diagrams in ROOT):**
```asciidoc
image::ROOT:uml/diagrams/BASE-classes.svg[]
```

### 4. Update Cross-References

**Within same module:**
```asciidoc
<<_section_name>>
or
xref:other-page.adoc[Link Text]
```

**To another module in same component:**
```asciidoc
xref:base_types:index.adoc[Base Types]
```

**To another component:**
```asciidoc
xref:RM:ehr:index.adoc[EHR in RM]
xref:1.0.3@RM:ehr:index.adoc[EHR in RM 1.0.3]
```

**Pattern:** `component:module:page.adoc` or `version@component:module:page.adoc`

### 5. Update Document Attributes

Some document attributes from AA_GLOBAL need to be referenced differently.

**Before:**
```asciidoc
:openehr-version: 1.0.4
```

**After:**
These are now defined globally in `antora-playbook.yml` and automatically available.

### 6. Create Navigation Files

Each module needs a `nav.adoc` file. The migration script creates a basic one, but you should enhance it:

**Example: modules/foundation_types/nav.adoc**
```asciidoc
.Foundation Types
* xref:index.adoc[Overview]
* xref:definitions.adoc[Definitions]
* xref:primitives.adoc[Primitive Types]
* xref:structures.adoc[Structures]
```

---

## Building and Testing

### Local Development Build

```bash
# Build from local repositories
make build-local

# Preview
make preview
```

Visit http://localhost:8080 to see your site.

### Production Build

```bash
# Build from remote GitHub repositories
make build
```

This fetches from GitHub and builds all specified versions.

### Docker Build

```bash
# Build using Docker
make docker-up
make build-docker
make preview-docker
```

### Continuous Integration

For CI/CD pipelines:

```bash
make ci-build
```

---

## Troubleshooting

### Issue: "antora.yml not found"

**Cause:** The repository hasn't been migrated yet.

**Solution:**
```bash
make migrate-repo REPO=specifications-BASE
```

### Issue: "Module not found" or broken navigation

**Cause:** Navigation file doesn't list the module or has incorrect references.

**Solution:** Check `antora.yml` and ensure all modules are listed in the `nav:` section.

### Issue: Images not displaying

**Cause:** Image paths haven't been updated to Antora format.

**Solution:** Update image references as shown in [Manual Adjustments](#manual-adjustments).

### Issue: Include directives not working

**Cause:** Include paths use old format.

**Solution:**
- For partials in same module: `include::partial$filename.adoc[]`
- For ROOT module partials: `include::ROOT:partial$path/filename.adoc[]`

### Issue: Cross-references broken

**Cause:** Cross-reference syntax not updated for Antora.

**Solution:** Use `xref:` format. See [Manual Adjustments](#manual-adjustments).

### Issue: Build fails with "version conflict"

**Cause:** Multiple branches have the same version in `antora.yml`.

**Solution:** Ensure each release branch has a unique version number in its `antora.yml`.

### Issue: "Cannot find module 'asciidoctor-kroki'"

**Cause:** npm dependencies not installed.

**Solution:**
```bash
npm install
```

---

## Appendices

### Appendix A: Component Descriptor (antora.yml) Reference

```yaml
name: BASE                          # Component name (must be unique)
title: BASE Component               # Display title
version: '1.1.0'                    # Version identifier
display_version: Release 1.1.0      # Display string for version
prerelease: false                   # Mark as prerelease (optional)
start_page: ROOT:index.adoc         # Landing page for component
nav:                                # Navigation configuration
  - modules/ROOT/nav.adoc
  - modules/foundation_types/nav.adoc
  - modules/base_types/nav.adoc
asciidoc:                           # Component-specific AsciiDoc settings
  attributes:
    component-version: '1.1.0'
```

### Appendix B: Resource ID Format

Antora uses a consistent format for referencing resources:

```
[version@]component:module:family$relative-path
```

**Examples:**
- `BASE:foundation_types:index.adoc` - Page in current version
- `1.0.3@RM:ehr:composition.adoc` - Page in specific version
- `ROOT:partial$uml/classes/LOCATABLE.adoc` - Partial file
- `ROOT:uml/diagrams/diagram.svg` - Image file

### Appendix C: File Naming Conventions

| Type | Location | Naming |
|------|----------|--------|
| Pages | `modules/*/pages/` | `kebab-case.adoc` |
| Partials | `modules/*/partials/` | `kebab-case.adoc` |
| Images | `modules/*/images/` | `kebab-case.svg/png/jpg` |
| Examples | `modules/*/examples/` | `kebab-case.*` |
| Navigation | `modules/*/` | `nav.adoc` |

### Appendix D: Makefile Targets Reference

```bash
# Repository Management
make clone-repos          # Clone all spec repositories
make update-repos         # Update all repositories
make create-branches      # Create release branches (single repo)
make create-all-branches  # Create release branches (all repos)

# Migration
make migrate-repo REPO=<name>    # Migrate single repository
make migrate-all                  # Migrate all repositories
make validate-structure REPO=<name>  # Validate single repository
make validate-all                 # Validate all repositories

# Building
make build                # Production build (from GitHub)
make build-local          # Local build (from repos/ directory)
make build-docker         # Build using Docker
make clean                # Clean build artifacts

# Preview
make preview              # Start local preview server
make preview-docker       # Preview in Docker

# Development
make dev-setup            # Complete development setup
make dev-rebuild          # Clean, rebuild, and preview

# Docker
make docker-build         # Build Docker image
make docker-up            # Start containers
make docker-down          # Stop containers
make docker-shell         # Open shell in container

# Information
make help                 # Show all targets
make list-repos           # List specification repositories
make check-deps           # Check required dependencies
```

### Appendix E: Migration Checklist

Use this checklist when migrating each repository:

- [ ] Clone repository to `repos/` directory
- [ ] Run `create-branches` to create release branches
- [ ] Run migration script in dry-run mode
- [ ] Review dry-run output
- [ ] Run actual migration
- [ ] Validate structure with `validate-structure`
- [ ] Update include directives for partials
- [ ] Update UML class includes
- [ ] Update image references
- [ ] Update cross-references
- [ ] Create/update navigation files
- [ ] Test build locally
- [ ] Review generated HTML
- [ ] Commit changes
- [ ] Push release branches to GitHub
- [ ] Update `antora-playbook.yml` to include new branches

### Appendix F: Batch Find-and-Replace Patterns

Use these patterns with your text editor for bulk updates:

**Update partial includes:**
```regex
Find:    include::master(\d\d)-(.+?)\.adoc\[\]
Replace: include::partial$\2.adoc[]
```

**Update UML class includes:**
```regex
Find:    include::\.\.\/\.\.\/UML\/classes\/(.+?)\.adoc\[\]
Replace: include::ROOT:partial$uml/classes/\1.adoc[]
```

**Update UML diagram images:**
```regex
Find:    image::\.\.\/UML\/diagrams\/(.+?)\[(.*?)\]
Replace: image::ROOT:uml/diagrams/\1[\2]
```

---

## Getting Help

- **Documentation:** https://docs.antora.org
- **openEHR Discourse:** https://discourse.openehr.org
- **GitHub Issues:** Create an issue in the openehr-antora repository

---

## License

This migration guide is part of the openEHR specifications project.
License: CC-BY-ND-3.0
