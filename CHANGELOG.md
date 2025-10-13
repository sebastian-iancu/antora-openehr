# Changelog

All notable changes to the openEHR Antora migration project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-10-12

### Added

- Initial Antora playbook configuration for openEHR specifications
- Local development playbook for testing with local repositories
- Comprehensive Makefile with targets for all common operations
- Docker and Docker Compose setup for containerized builds
- Migration script (`migrate-repo.sh`) to transform repositories to Antora structure
- Script to create release branches from git tags (`create-release-branches.sh`)
- Validation script (`validate-structure.sh`) to check Antora compliance
- Comprehensive migration guide (MIGRATION-GUIDE.md)
- Example structures showing before/after migration
- Custom CSS for openEHR branding
- Supplemental UI directory structure for customization
- package.json with required Node.js dependencies
- .gitignore for common files to exclude
- Detailed README with quick start guide

### Migration Features

- Automatic directory restructuring (docs/ → modules/)
- UML content organization (classes → partials, diagrams → images)
- Component descriptor (antora.yml) generation
- Navigation file creation for each module
- Support for multiple specification components (BASE, RM, AM, etc.)
- Preservation of existing content with minimal changes
- Dry-run mode for testing migrations

### Build Features

- Multi-version support via git branches
- Component-based architecture
- Cross-component references
- Custom styling and branding
- Docker-based builds
- Local and production build configurations

### Documentation

- Step-by-step migration guide
- Troubleshooting section
- Appendices with reference material
- File naming conventions
- Resource ID format documentation
- Makefile targets reference
- Migration checklist

## [Unreleased]

### Planned

- Automated testing of migrated content
- CI/CD pipeline configuration
- Search integration using Lunr
- PDF generation from Antora output
- Additional UI themes
- Migration verification reports
- Automated include directive updates
- Performance optimizations

### Known Issues

- Manual updates required for include directives after migration
- Image references need manual correction
- Navigation files need manual enhancement
- Cross-references require manual updates to Antora format

---

## Migration Status by Component

| Component | Status | Notes |
|-----------|--------|-------|
| BASE      | 🟡 Ready for testing | Scripts ready, needs manual testing |
| RM        | 🟡 Ready for testing | Scripts ready, needs manual testing |
| AM        | 🟡 Ready for testing | Scripts ready, needs manual testing |
| LANG      | 🟡 Ready for testing | Scripts ready, needs manual testing |
| SM        | 🟡 Ready for testing | Scripts ready, needs manual testing |
| QUERY     | 🟡 Ready for testing | Scripts ready, needs manual testing |
| PROC      | 🟡 Ready for testing | Scripts ready, needs manual testing |
| CDS       | 🟡 Ready for testing | Scripts ready, needs manual testing |
| CNF       | 🟡 Ready for testing | Scripts ready, needs manual testing |
| ITS       | 🟡 Ready for testing | Scripts ready, needs manual testing |

Legend:
- 🟢 Complete and tested
- 🟡 Ready for testing
- 🟠 In progress
- 🔴 Not started

---

For more information, see [README.md](README.md) and [MIGRATION-GUIDE.md](MIGRATION-GUIDE.md).
