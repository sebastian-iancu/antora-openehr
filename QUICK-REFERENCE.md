# Quick Reference Card

## Common Commands

Note: Environment setup (Node/Docker) is documented in [START-HERE.md](). This card lists day-to-day commands only.

### Repository Prep

```bash
# From project root
make install
make create-all-branches
```

### Available commands

```bash
make help
```

### Migrate Single Repository

```bash
# Test migration first (dry run)
cd repos/specifications-BASE
../../scripts/migration/main-migrate-repo.sh . dry-run

# Perform actual migration
make migrate-repo REPO=specifications-BASE

# Validate
make validate-structure REPO=specifications-BASE
```

### Build and Preview

```bash
# Build from local repos
make build-local

# Start preview server
make preview
# Visit http://localhost:8080
```

### Using Docker as a provider for node/npm

```bash
# Build Docker image
docker compose build

# Start containers
docker compose up -d

# Start a shell into the running container
docker compose exec antora bash

# Stop containers
docker compose down
```

## Antora Reference Formats

### Include Directives

```asciidoc
# Partial in same module
include::partial$filename.adoc[]

# Partial in ROOT module
include::ROOT:partial$path/filename.adoc[]

# Example file
include::example$code.java[]
```

### Image References

```asciidoc
# Image in same module
image::diagrams/diagram.svg[]

# Image in ROOT module
image::ROOT:uml/diagrams/diagram.svg[]

# With attributes
image::ROOT:uml/diagrams/diagram.svg[Alt text,800,align=center]
```

### Cross References

```asciidoc
# Within same page
<<_section_anchor>>

# To another page in same module
xref:other-page.adoc[Link text]

# To another module in same component
xref:other-module:page.adoc[Link text]

# To another component
xref:RM:ehr:index.adoc[EHR in RM]

# To specific version
xref:1.0.3@RM:ehr:index.adoc[EHR in RM 1.0.3]
```

## Directory Structure Reference

```
component-repo/
├── antora.yml           # Component descriptor
└── modules/
    ├── ROOT/            # Shared content
    │   ├── pages/
    │   ├── partials/
    │   └── images/
    └── module-name/     # Each specification doc
        ├── nav.adoc
        ├── pages/
        ├── partials/
        └── images/
```

## File Naming Patterns

| Type | Pattern | Example |
|------|---------|---------|
| Pages | kebab-case.adoc | foundation-types.adoc |
| Partials | kebab-case.adoc | primitive-types.adoc |
| Images | kebab-case.ext | class-diagram.svg |
| Navigation | nav.adoc | nav.adoc |

## Migration Checklist

- [ ] Clone repository to repos/
- [ ] Create release branches
- [ ] Run migration script
- [ ] Validate structure
- [ ] Update include directives
- [ ] Update image references
- [ ] Update cross-references
- [ ] Test build locally
- [ ] Commit changes
- [ ] Push to remote

## Troubleshooting

| Problem | Solution |
|---------|----------|
| antora.yml not found | Run migration script |
| Images not showing | Update image paths |
| Includes broken | Use partial$ prefix |
| Build fails | Check validation output |
| Version conflict | Ensure unique versions |

## Key Concepts

**Component**: A documentation unit (BASE, RM, AM, etc.)
**Module**: A section within a component (foundation_types, base_types, etc.)
**Version**: Git branch (master, release/1.0.3, etc.)
**Resource ID**: `[version@]component:module:family$path`

## Useful Links

- Antora Docs: https://docs.antora.org
- AsciiDoc Syntax: https://docs.asciidoctor.org
- openEHR Specs: https://specifications.openehr.org
- Start here (setup): [START-HERE.md]()
- Migration Guide: [MIGRATION-GUIDE.md]()

## Support

- GitHub Issues: https://github.com/sebastian-iancu/antora-openehr/issues
- Documentation: See [README.md]() and [MIGRATION-GUIDE.md]()
