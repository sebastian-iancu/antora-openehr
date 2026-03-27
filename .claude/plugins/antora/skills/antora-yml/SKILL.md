---
name: antora-yml
description: >-
  Use when creating, editing, reviewing, or troubleshooting an antora.yml
  component version descriptor. Covers all keys (name, version, title,
  display_version, start_page, nav, prerelease, asciidoc.attributes),
  validation rules for name and version values, nav registration,
  versioning strategies, and common mistakes.
---

# antora.yml — Component Version Descriptor

The `antora.yml` file identifies a documentation component version to Antora.
It must be placed at the **content source root** — the directory that also
contains the `modules/` folder.

---

## All Keys Reference

### Required Keys

#### `name`

The component name. Combined with `version` to uniquely identify a component version.

```yaml
name: RM
```

**Validation rules:**
- **Required** — cannot be empty
- Valid characters: letters, numbers, underscores (`_`), hyphens (`-`), periods (`.`)
- **Forbidden:** spaces, forward slashes (`/`), HTML special characters (`&`, `<`, `>`)
- **Case-sensitive** — `RM` and `rm` are different components
- **Strongly recommended:** use only lowercase characters for URL portability
- Becomes the component segment in page URLs (e.g., `/RM/ehr/index.html`)
- Special value `ROOT` with `version: ~` places content at site root (no component URL segment)

#### `version`

The version identifier. Combined with `name` to uniquely identify a component version.

```yaml
version: '1.1.0'
```

**Validation rules:**
- **Required** — unless inherited from the playbook content source `version` key
- Valid characters: letters, numbers, periods (`.`), underscores (`_`), hyphens (`-`)
- **Forbidden:** spaces, forward slashes (`/`), HTML special characters (`&`, `<`, `>`)
- **Strongly recommended:** lowercase letters for portability
- **Quote numeric values** in single quotes to prevent YAML number parsing: `'1.0'` not `1.0`
- Becomes the version segment in URLs

**Special values:**
| Value | Meaning |
|-------|---------|
| `~` (tilde/null) | Unversioned component — no version segment in URL |
| `true` | Use the git refname (branch/tag name) as the version value |

**Semantic versioning note:** If the version is an integer or starts with an integer
containing at least one dot (e.g., `1.0.3`), Antora treats it as a semantic identifier
for sorting. A leading `v` prefix (e.g., `v1.0.3`) is allowed and ignored during sorting.

---

### Optional Keys

#### `title`

Human-readable component name for UI display and sorting.

```yaml
title: Reference Model
```

- Accepts spaces, uppercase, and special characters
- Used in navigation menus, breadcrumbs, component selectors
- If not set, `name` is used in the UI instead
- Does **not** affect URLs or resource IDs

#### `display_version`

Human-readable version string for UI display only.

```yaml
display_version: '1.1.0 (Stable)'
```

- Accepts spaces, uppercase, and most characters (e.g., `3.0 Beta`, `RED WREN!`)
- Shown in component version selector and page version selector
- Does **not** affect URLs, resource IDs, routing, or version sorting
- If not set, falls back to the `version` value

#### `start_page`

The landing page for this component version.

```yaml
start_page: ROOT:index.adoc
```

- Value is an Antora page resource ID (relative to this component)
- Default: `ROOT:index.adoc` (the `index.adoc` page in the ROOT module)
- Format: `[module:]page.adoc` — module defaults to ROOT if omitted

#### `prerelease`

Marks this component version as a prerelease.

```yaml
prerelease: true
# or with identifier suffix:
prerelease: -alpha.2
```

- `true` or a string starting with `-` (appended to display version)
- Deactivates default routing (prerelease is not the "latest" version)
- When set to a string, appended to `display_version` if not explicitly set

#### `nav`

Ordered list of navigation file paths to include in the site menu.

```yaml
nav:
  - modules/ROOT/nav.adoc
  - modules/ehr/nav.adoc
  - modules/demographic/nav.adoc
```

- Paths are **relative to the content source root** (where `antora.yml` lives)
- Order in the list determines display order in the component navigation menu
- Each referenced file must exist and contain valid AsciiDoc unordered lists
- One `nav.adoc` per module is the common convention
- Files not listed here are **not** included in the navigation

#### `asciidoc.attributes`

AsciiDoc document attributes applied to all pages in this component version.

```yaml
asciidoc:
  attributes:
    rm-version: '1.1.0'
    component-name: RM
    page-status: stable
    # Hard-set (cannot be overridden per page):
    experimental: ''
    # Soft-set (can be overridden per page — append @):
    toc: left@
```

- Nested under `asciidoc:` → `attributes:`
- Merged with playbook-level attributes (component attributes take precedence)
- Attributes ending with `@` are **soft-set** — pages can override them
- Attributes without `@` are **hard-set** — pages cannot override them
- Set an attribute to `false` to unset/disable it

---

## Complete Example

```yaml
name: RM
version: '1.1.0'
title: Reference Model
display_version: '1.1.0 (Stable)'
start_page: ROOT:index.adoc
prerelease: false
nav:
  - modules/ROOT/nav.adoc
  - modules/ehr/nav.adoc
  - modules/demographic/nav.adoc
  - modules/common/nav.adoc
  - modules/data_structures/nav.adoc
  - modules/data_types/nav.adoc
  - modules/support/nav.adoc
  - modules/integration/nav.adoc
  - modules/ehr_extract/nav.adoc
asciidoc:
  attributes:
    rm-version: '1.1.0'
    rm-release: 'Release-1.1.0'
```

---

## Common Mistakes

### 1. Unquoted numeric version

```yaml
# WRONG — YAML parses 1.0 as a float
version: 1.0

# CORRECT — quoted string
version: '1.0'
```

### 2. Spaces or slashes in name

```yaml
# WRONG
name: Reference Model
name: specs/RM

# CORRECT
name: RM
name: reference-model
```

### 3. Nav path does not match filesystem

```yaml
# WRONG — module directory is ehr, not EHR
nav:
  - modules/EHR/nav.adoc

# CORRECT — case must match exactly
nav:
  - modules/ehr/nav.adoc
```

### 4. Nav file not at module root

```yaml
# WRONG — nav.adoc should be in modules/ehr/, not modules/ehr/pages/
nav:
  - modules/ehr/pages/nav.adoc

# CORRECT
nav:
  - modules/ehr/nav.adoc
```

### 5. Missing start_page target

```yaml
# WRONG if modules/ROOT/pages/index.adoc doesn't exist
start_page: ROOT:index.adoc

# FIX: create the file or point to an existing page
start_page: ROOT:overview.adoc
```

### 6. Version vs display_version confusion

```yaml
# URL-safe version for routing (required):
version: '2.0.0-beta'

# Human-readable version for UI (optional):
display_version: '2.0.0 Beta'
```

---

## Versioning Strategies

### Branch-Based (used in this project)

Each git branch represents a version. The playbook content source specifies which
branches to include:

```yaml
# In playbook:
content:
  sources:
    - url: ./repos/specifications-RM
      branches: [HEAD, release/1.0.3, release/1.1.0]
```

Each branch has its own `antora.yml` with the appropriate `version` value.

### Tag-Based

```yaml
# In antora.yml:
version: true  # Use the git refname as version
```

### Unversioned

```yaml
version: ~
```

Single version, no version segment in URLs.

---

## openEHR Project Patterns

In this repository, `antora.yml` files follow these conventions:

- `name` uses uppercase component abbreviations: `BASE`, `RM`, `AM`, `LANG`, `SM`, `QUERY`, `PROC`, `CDS`, `CNF`, `ITS-REST`, `ITS-JSON`, `ITS-XML`, `ITS-BMM`
- `title` is the human-readable component name
- `start_page` always points to `ROOT:index.adoc`
- `nav` lists `modules/ROOT/nav.adoc` first, then one per named module
- The playbook uses `branches: HEAD` and `version: development` for local builds
- Migration script `5-create-antora-yml.sh` generates the initial `antora.yml`
