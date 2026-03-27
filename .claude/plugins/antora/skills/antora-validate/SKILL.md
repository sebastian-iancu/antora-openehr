---
name: antora-validate
description: >-
  Use when validating an Antora project structure, reviewing an antora.yml for
  correctness, diagnosing build errors like "file not found" or "resource not
  in catalog", checking nav consistency, or verifying a repository is ready
  for an Antora build. Provides a systematic checklist and integrates with the
  project's existing validate-structure.sh script.
---

# Antora Project Validation

This skill provides a systematic approach to validating Antora project structure
and `antora.yml` correctness. Use it before builds, after migrations, or when
diagnosing errors.

---

## Validation Approach

### Step 1: Run the existing validation script

The project includes a shell-based validator. Run it first:

```bash
make validate-structure REPO=specifications-<NAME>
# or directly:
bash scripts/validate-structure.sh repos/specifications-<NAME>
```

This checks:
- `antora.yml` exists with `name` (error), `version` (warning), `start_page` (warning)
- `modules/` directory exists with a `ROOT` module
- Each module has `pages/`, `partials/`, `nav.adoc`
- ROOT has `partials/component_vars.adoc`; named modules have `partials/module_vars.adoc`
- No leftover `docs/` directory from pre-migration
- Include directives use `partial$` or `example$` prefixes

### Step 2: Deeper validation (beyond the script)

The shell script covers basics. Perform these additional checks manually or
with Claude's help:

---

## antora.yml Validation Rules

### name key
- [ ] Present and non-empty
- [ ] Only contains: lowercase letters, numbers, `_`, `-`, `.`
- [ ] No spaces, `/`, `&`, `<`, `>`
- [ ] Matches the intended component identifier

### version key
- [ ] Present (or inherited from playbook content source)
- [ ] Quoted if numeric: `'1.0.3'` not `1.0.3`
- [ ] Only contains: letters, numbers, `.`, `_`, `-`
- [ ] No spaces, `/`, `&`, `<`, `>`
- [ ] Special values `~` or `true` used correctly if present

### title key (optional)
- [ ] If present, provides a human-readable component name
- [ ] Does not duplicate `name` without adding value

### start_page key
- [ ] Target page actually exists at the referenced path
- [ ] Format is valid: `[module:]page.adoc`
- [ ] Default `ROOT:index.adoc` — verify `modules/ROOT/pages/index.adoc` exists

### nav key
- [ ] Every path in the list points to an existing `nav.adoc` file
- [ ] Paths are relative to content source root (where `antora.yml` lives)
- [ ] Format: `modules/<module>/nav.adoc`
- [ ] Order reflects desired menu display order
- [ ] Every module that should appear in navigation has its `nav.adoc` listed

### nav.adoc cross-check
- [ ] Every `nav.adoc` listed in `antora.yml` exists on disk
- [ ] Every module directory with a `nav.adoc` is listed in `antora.yml` (unless intentionally excluded)
- [ ] Nav files contain valid AsciiDoc unordered lists
- [ ] `xref:` targets in nav files point to existing pages

---

## Directory Structure Validation Rules

### Content source root
- [ ] `antora.yml` and `modules/` are siblings in the same directory
- [ ] No content files exist outside `modules/` that should be inside it

### Modules directory
- [ ] At least one module directory exists
- [ ] ROOT module (if present) is spelled exactly `ROOT`
- [ ] Named module directories use valid names: lowercase, numbers, `_`, `-`
- [ ] No directories with spaces, dots, or uppercase in `modules/`

### Family directories
- [ ] Only standard names used: `pages`, `partials`, `images`, `examples`, `attachments`
- [ ] No misspellings: `page` (should be `pages`), `partial` (should be `partials`), `image` (should be `images`)
- [ ] Each family directory contains at least one relevant file
- [ ] No content files placed directly in the module root (should be in a family dir)

### Navigation files
- [ ] `nav.adoc` is at module root, NOT inside `pages/` or `partials/`
- [ ] Contains AsciiDoc unordered list syntax (`*`, `**`, `***`)
- [ ] All `xref:` targets resolve to existing `.adoc` files in `pages/`

---

## Common Build Error Diagnosis

### "antora.yml not found"

**Cause:** Content source root doesn't contain `antora.yml`.
**Check:**
1. Verify the file exists: `ls repos/<REPO>/antora.yml`
2. Check the playbook `start_path` if using a subdirectory
3. Ensure the branch/tag referenced in the playbook actually has the file

### "resource not in catalog" / "unresolved xref"

**Cause:** A cross-reference points to a page, partial, or image that Antora
can't find in its content catalog.
**Check:**
1. Target file exists in the correct family directory
2. Resource ID is correctly formed: `[version@][component:][module:]family$path`
3. File is not hidden (starts with `.`) or extensionless
4. Module name in xref matches directory name exactly (case-sensitive)

### "nav list not found" / empty navigation

**Cause:** `nav.adoc` is missing, misreferenced, or has no list content.
**Check:**
1. File path in `antora.yml` `nav` key matches actual filesystem path
2. `nav.adoc` contains at least one `*` list item
3. File is not empty or commented out

### "duplicate component version"

**Cause:** Two content sources produce the same `name` + `version` combination.
**Check:**
1. Each branch/source has a unique version in its `antora.yml`
2. The playbook doesn't include the same branch twice
3. No overlapping `branches` patterns in playbook content sources

### Images not rendering

**Cause:** Image path doesn't match Antora's resource ID scheme.
**Check:**
1. Image file is in the `images/` family directory (not `pages/` or root)
2. Reference uses correct syntax: `image::filename.svg[]` (same module) or `image::ROOT:path/filename.svg[]` (cross-module)
3. File extension is present and correct

---

## Validation Commands Quick Reference

```bash
# Validate single repo structure
make validate-structure REPO=specifications-RM

# Validate all repos
make validate-all

# Check if antora.yml parses correctly (no YAML errors)
python3 -c "import yaml; yaml.safe_load(open('repos/specifications-RM/antora.yml'))"
# or with node:
node -e "const y=require('js-yaml'); console.log(y.load(require('fs').readFileSync('repos/specifications-RM/antora.yml','utf8')))"

# Find nav.adoc files not registered in antora.yml
find repos/specifications-RM/modules -name nav.adoc

# Find modules without nav.adoc
for d in repos/specifications-RM/modules/*/; do [ ! -f "$d/nav.adoc" ] && echo "Missing nav: $d"; done

# Check for misplaced nav.adoc (inside family dirs)
find repos/specifications-RM/modules -path '*/pages/nav.adoc' -o -path '*/partials/nav.adoc'

# Build and capture errors
make build-local 2>&1 | tee build.log
grep -i 'error\|warn' build.log
```
