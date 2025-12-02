# openEHR Specifications - Antora Migration Project

[![Build Status](https://img.shields.io/badge/build-passing-brightgreen)]()
[![Antora](https://img.shields.io/badge/Antora-3.1-blue)]()
[![License](https://img.shields.io/badge/license-CC--BY--ND--3.0-lightgrey)]()

This repository contains the build system and migration tools for converting openEHR specifications from their current AsciiDoc structure to [Antora](https://antora.org), a multi-repository documentation site generator.

## 📋 Table of Contents

- [Overview](#overview)
- [Quick Start](#quick-start)
- [Repository Structure](#repository-structure)
- [Migration Process](#migration-process)
- [Building Documentation](#building-documentation)
- [Contributing](#contributing)
- [Documentation](#documentation)

## 🎯 Overview

### What This Project Does

This project provides:

1. **Antora Playbook** - Configuration for building multi-version openEHR specifications
2. **Migration Scripts** - Automated tools to transform repositories to Antora structure
3. **Validation Tools** - Scripts to verify correct Antora structure
4. **Build System** - Makefile and Docker setup for easy builds
5. **Documentation** - Comprehensive migration guide

### Why Antora?

Antora enables us to:

- ✅ Support multiple versions (Release-1.0.2, 1.0.3, etc.) from git branches
- ✅ Keep components in separate repositories
- ✅ Build a unified documentation site
- ✅ Maintain clean separation of concerns
- ✅ Enable easy cross-referencing between components and versions

## 🚀 Quick Start

### Prerequisites

- Git
- Node.js 16+ and npm
- Make
- Docker (optional, for containerized builds)

### Installation
Recursive cloning might require [SSH authentication to github](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
```bash
# Clone this repository
clone repo `git clone --recursive`

cd openehr-antora

# Install dependencies
npm install

# Or use Docker
make docker-build
```

### Basic Usage

```bash
# 1. Clone all specification repositories
make clone-repos

# 2. Create release branches from tags
make create-all-branches

# 3. Migrate repositories to Antora structure
make migrate-all

# 4. Build the documentation site
make build-local

# 5. Preview the site
make preview
```

Visit http://localhost:8080 to see your documentation site!

## 📁 Repository Structure

```
openehr-antora/
├── antora-playbook.yml              # Main Antora configuration
├── antora-playbook-local.yml        # Local development configuration
├── package.json                     # Node.js dependencies
├── Makefile                         # Build automation
├── Dockerfile                       # Docker image definition
├── docker-compose.yml               # Docker Compose configuration
│
├── scripts/
│   ├── create-release-branches.sh   # Convert git tags to branches
│   ├── migrate-repo.sh              # Migrate repo to Antora structure
│   └── validate-structure.sh        # Validate Antora structure
│
├── supplemental-ui/
│   ├── css/
│   │   └── openehr.css              # Custom styling
│   ├── img/                         # Shared images (from AA_GLOBAL)
│   └── partials/
│       └── header-content.hbs       # Custom header template
│
├── examples/
│   ├── before/                      # Example of current structure
│   └── after/                       # Example of Antora structure
│
├── repos/                           # Cloned specification repositories
│   ├── specifications-BASE/
│   ├── specifications-RM/
│   ├── specifications-AM/
│   └── ...
│
├── build/                           # Generated site output
│   └── site/
│
├── MIGRATION-GUIDE.md               # Comprehensive migration guide
└── README.md                        # This file
```

## 🔄 Migration Process

### Step-by-Step

1. **Clone Repositories**
   ```bash
   make clone-repos
   ```

2. **Create Release Branches**
   ```bash
   make create-all-branches
   ```
   This converts git tags like `Release-1.0.3` to branches `release/1.0.3`.

3. **Migrate Structure**
   ```bash
   # Single repository
   make migrate-repo REPO=specifications-BASE
   
   # All repositories
   make migrate-all
   ```

4. **Manual Updates**
   
   After migration, update AsciiDoc files:
   - Update `include::` directives to use `partial$` prefix
   - Update image references
   - Update cross-references to Antora format
   
   See [MIGRATION-GUIDE.md](MIGRATION-GUIDE.md) for details.

5. **Validate Structure**
   ```bash
   make validate-structure REPO=specifications-BASE
   ```

6. **Build and Test**
   ```bash
   make build-local
   make preview
   ```

### What Gets Migrated?

#### Before Migration
```
docs/
├── foundation_types/
│   ├── master.adoc
│   ├── master01-preface.adoc
│   └── master02-overview.adoc
└── UML/
    ├── classes/
    └── diagrams/
```

#### After Migration
```
modules/
├── ROOT/
│   ├── pages/index.adoc
│   ├── partials/uml/classes/
│   └── images/uml/diagrams/
└── foundation_types/
    ├── pages/index.adoc
    └── partials/
        ├── preface.adoc
        └── overview.adoc
```

## 🏗️ Building Documentation

### Local Build (Development)

```bash
# Build from local repositories
make build-local

# Preview
make preview
```

### Production Build

```bash
# Build from GitHub (uses branches from remote repos)
make build
```

### Docker Build

```bash
# Start Docker environment
make docker-up

# Build in Docker
make build-docker

# Preview (served at http://localhost:8080)
make preview-docker
```

### Clean Build

```bash
# Clean build artifacts
make clean

# Clean everything including cloned repos
make clean-all
```

## 🎨 Customization

### Styling

Custom CSS is in `supplemental-ui/css/openehr.css`. This file contains:
- openEHR branding colors
- Component-specific styling
- UML diagram styling
- Table and code block styling

### UI Templates

Custom Handlebars templates are in `supplemental-ui/partials/`:
- `header-content.hbs` - Custom header
- Add more templates as needed

### Global Attributes

Global AsciiDoc attributes (migrated from AA_GLOBAL) are in `antora-playbook.yml`:

```yaml
asciidoc:
  attributes:
    openehr-version: '1.0.4'
    spec-base-url: 'https://specifications.openehr.org'
    # Add more attributes here
```

## 🤝 Contributing

### For Specification Authors

If you're updating specification content:

1. Work in your component repository (e.g., `specifications-BASE`)
2. Follow Antora conventions:
   - Pages go in `modules/*/pages/`
   - Partials go in `modules/*/partials/`
   - Images go in `modules/*/images/`
3. Use correct include syntax: `include::partial$filename.adoc[]`
4. Test locally before committing

### For Build System Developers

If you're improving the build system:

1. Fork this repository
2. Make your changes
3. Test with `make build-local`
4. Submit a pull request

## 📚 Documentation

- **[MIGRATION-GUIDE.md](MIGRATION-GUIDE.md)** - Comprehensive migration guide
- **[examples/before/](examples/before/)** - Current structure examples
- **[examples/after/](examples/after/)** - Antora structure examples
- **[Antora Documentation](https://docs.antora.org)** - Official Antora docs

## 🛠️ Available Make Targets

```bash
# Repository Management
make clone-repos              # Clone all specification repositories
make update-repos             # Update all repositories
make create-branches REPO=... # Create release branches from tags
make create-all-branches      # Create branches for all repos

# Migration
make migrate-repo REPO=...    # Migrate single repository
make migrate-all              # Migrate all repositories
make validate-structure REPO=...  # Validate single repository
make validate-all             # Validate all repositories

# Building
make build                    # Production build (from GitHub)
make build-local              # Local build (from repos/ dir)
make build-docker             # Build using Docker
make clean                    # Clean build artifacts

# Preview
make preview                  # Start local preview server
make preview-docker           # Preview in Docker

# Docker
make docker-build             # Build Docker image
make docker-up                # Start containers
make docker-down              # Stop containers
make docker-shell             # Open shell in container

# Development
make dev-setup                # Initial development setup
make dev-rebuild              # Clean, rebuild, and preview

# Information
make help                     # Show all available targets
make list-repos               # List specification repositories
make check-deps               # Check required dependencies
```

## 🐛 Troubleshooting

### Common Issues

**Problem:** "antora.yml not found"
- **Solution:** Run `make migrate-repo REPO=<repo-name>` first

**Problem:** Images not displaying
- **Solution:** Check image paths use Antora format (see MIGRATION-GUIDE.md)

**Problem:** Include directives broken
- **Solution:** Update to use `partial$` prefix

**Problem:** Build fails with version conflict
- **Solution:** Ensure each branch has unique version in antora.yml

For more troubleshooting, see [MIGRATION-GUIDE.md](MIGRATION-GUIDE.md#troubleshooting).

## 📄 License

The openEHR specifications are licensed under CC-BY-ND-3.0.

Build system and tools: Apache License 2.0

## 🔗 Links

- [openEHR Website](https://www.openehr.org)
- [openEHR Specifications](https://specifications.openehr.org)
- [Antora Documentation](https://docs.antora.org)
- [openEHR Discourse](https://discourse.openehr.org)

## 📧 Contact

For questions or issues:
- Open an issue in this repository
- Post on [openEHR Discourse](https://discourse.openehr.org)
- Contact the openEHR Specifications Editorial Committee (SEC)

---

**Status:** 🚧 Active Development | **Last Updated:** October 2025
