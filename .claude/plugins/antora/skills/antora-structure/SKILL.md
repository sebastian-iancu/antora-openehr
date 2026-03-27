---
name: antora-structure
description: >-
  Use when working with Antora project directory layout, creating or reorganizing
  module directories, adding family directories (pages, partials, images, examples,
  attachments), setting up a new component, or troubleshooting "file not found"
  and "resource not in catalog" errors. Covers the standard directory hierarchy,
  ROOT vs named modules, family directory roles, file naming rules, and how
  Antora discovers content.
---

# Antora Standard Directory Structure

## Content Source Root

Every Antora component version lives at a **content source root** — the directory
containing `antora.yml` and the sibling `modules/` directory. This is the minimum
structure Antora requires to recognize a documentation component:

```
<content-source-root>/
├── antora.yml          # REQUIRED — component version descriptor
└── modules/            # REQUIRED — contains all module directories
    └── <module>/       # At least one module with one family dir + one file
```

Anything outside `modules/` is ignored by Antora (build scripts, CI configs, app code, etc.).

---

## Modules Directory

The `modules/` directory is **required** wherever `antora.yml` exists. It contains
one or more **module directories**, each grouping content by concept, feature, or
document scope.

### ROOT Module

- Directory name: `ROOT` (all uppercase, exact spelling)
- Special behavior: content published **without** a module segment in the URL
- Common use: landing pages, shared partials (e.g. UML classes), shared images
- The default `start_page` resolves to `ROOT:index.adoc` if not overridden

### Named Modules

- Any directory inside `modules/` that is not `ROOT`
- The directory name **becomes** the module name and URL segment
- Naming rules:
  - Use lowercase letters, numbers, underscores (`_`), hyphens (`-`)
  - No spaces, no dots, no special characters
  - Convention: `snake_case` or `kebab-case`
- Examples: `foundation_types`, `ehr`, `data-types`, `query`

### Module Configuration

Modules have **no individual configuration file**. All metadata comes from the
component-level `antora.yml`. A module's identity is solely its directory name.

---

## Family Directories

Each module can contain up to **five** family directories. Each is optional — only
create the ones you need.

| Family | Directory | Publishable | Purpose |
|--------|-----------|-------------|---------|
| Pages | `pages/` | Yes | AsciiDoc content pages — each becomes an HTML page |
| Partials | `partials/` | No | Reusable AsciiDoc snippets included via `include::partial$...[]` |
| Images | `images/` | Yes | Image files (SVG, PNG, JPG) referenced via `image::...[]` |
| Examples | `examples/` | No | Code samples and data files included via `include::example$...[]` |
| Attachments | `attachments/` | Yes | Downloadable files linked via `link:{attachmentsdir}/...[]` |

### Subdirectories Within Family Dirs

You can nest subdirectories freely inside any family directory. The subdirectory
path becomes part of the resource ID:

```
modules/ehr/
├── pages/
│   ├── index.adoc              → ehr:index.adoc
│   └── data-types/
│       └── quantity.adoc       → ehr:data-types/quantity.adoc
├── partials/
│   └── uml/
│       └── classes/
│           └── ehr-class.adoc  → ehr:partial$uml/classes/ehr-class.adoc
└── images/
    └── diagrams/
        └── ehr-overview.svg    → ehr:image$diagrams/ehr-overview.svg
```

---

## File Discovery Rules

### Indexed and Published

Standard files in `pages/`, `images/`, and `attachments/` are added to the content
catalog **and** published as HTML pages or static assets.

### Indexed but NOT Published

- Files in `partials/` and `examples/` — referenceable but not standalone pages
- Files whose name starts with `_` (underscore) in any family dir — added to
  catalog, get a resource ID, but not auto-published

### Ignored (Not Indexed)

- Files whose name starts with `.` (dot) — hidden files, completely ignored
- Files without a file extension (except in `examples/` and `partials/`)
- Anything outside the `modules/` directory tree

---

## Navigation Files

- File name: `nav.adoc` (exact name, placed at module root, NOT inside a family dir)
- Contains AsciiDoc unordered lists with `xref:` links to pages
- Must be registered in `antora.yml` under the `nav` key to appear in the site menu
- One `nav.adoc` per module is the common pattern, but not required

```
modules/
├── ROOT/
│   ├── nav.adoc        # ← at module root, not inside pages/
│   └── pages/
│       └── index.adoc
└── ehr/
    ├── nav.adoc
    └── pages/
        └── index.adoc
```

### nav.adoc Syntax

```asciidoc
* xref:index.adoc[EHR Information Model]
** xref:ehr-object.adoc[EHR Object]
** xref:composition.adoc[Composition]
*** xref:entry-types.adoc[Entry Types]
* xref:common:index.adoc[Common IM]
```

- `*` = top-level entry; `**` = nested; `***` = deeper nesting
- Plain text entries (no xref) create unlinked category headers
- Cross-module refs use `xref:module:page.adoc[...]`

---

## Complete Example Structure

```
specifications-RM/
├── antora.yml
└── modules/
    ├── ROOT/
    │   ├── nav.adoc
    │   ├── pages/
    │   │   └── index.adoc
    │   ├── partials/
    │   │   └── uml/classes/
    │   │       ├── ehr-class.adoc
    │   │       └── composition-class.adoc
    │   └── images/
    │       └── uml/diagrams/
    │           └── rm-overview.svg
    ├── ehr/
    │   ├── nav.adoc
    │   ├── pages/
    │   │   ├── index.adoc
    │   │   └── ehr-object.adoc
    │   ├── partials/
    │   │   └── module_vars.adoc
    │   └── images/
    │       └── ehr-diagram.svg
    └── demographic/
        ├── nav.adoc
        ├── pages/
        │   └── index.adoc
        └── partials/
            └── module_vars.adoc
```

---

## Quick Validation Checklist

1. `antora.yml` exists at content source root
2. `modules/` directory exists as sibling of `antora.yml`
3. At least one module directory exists inside `modules/`
4. That module has at least one family directory with at least one source file
5. `ROOT` module (if present) is spelled exactly `ROOT` (all caps)
6. Named modules use only lowercase letters, numbers, underscores, hyphens
7. Family directories use exact names: `pages`, `partials`, `images`, `examples`, `attachments`
8. `nav.adoc` files sit at module root (not inside family directories)
9. Every `nav.adoc` referenced in `antora.yml` `nav` key actually exists
10. No content files rely on being outside `modules/` — Antora ignores them

---

## openEHR Project Conventions

In this repository, migrated specification repos follow additional conventions:

- `ROOT` module holds shared UML classes (`partials/uml/classes/`) and diagrams (`images/uml/diagrams/`)
- ROOT must contain `partials/component_vars.adoc` (component-level variables)
- Named modules must contain `partials/module_vars.adoc` (module-level variables)
- Each module should have an `index.adoc` in `pages/`
- Navigation files are registered in order in `antora.yml`

Use `make validate-structure REPO=<name>` to run the project's structural validation script.
