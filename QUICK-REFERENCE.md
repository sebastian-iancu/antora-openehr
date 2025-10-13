# Quick Reference Card

## Common Commands

### Initial Setup

```bash
# Clone and set up
git clone <repo-url>
cd openehr-antora
npm install
make clone-repos
make create-all-branches
```

### Migrate Single Repository

```bash
# Test migration first (dry run)
cd repos/specifications-BASE
../../scripts/migrate-repo.sh . dry-run

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

### Using Docker

```bash
# Build Docker image
make docker-build

# Start containers
make docker-up

# Build in Docker
make build-docker

# Preview
make preview-docker

# Stop containers
make docker-down
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
- Migration Guide: MIGRATION-GUIDE.md

## Support

- GitHub Issues: <repo-url>/issues
- openEHR Discourse: https://discourse.openehr.org
- Documentation: See README.md and MIGRATION-GUIDE.md
