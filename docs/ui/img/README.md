# Supplemental UI Images

This directory should contain images migrated from specifications-AA_GLOBAL repository.

## Files to migrate:

- `openehr-logo.png` - Main openEHR logo
- `openehr-icon.png` - Favicon
- Any other shared images used across specifications

## Usage in templates:

Images in this directory can be referenced in Handlebars templates:

```handlebars
<img src="{{{uiRootPath}}}/img/openehr-logo.png" alt="openEHR">
```

## Migration steps:

1. Copy images from `specifications-AA_GLOBAL/images/` to this directory
2. Update references in `supplemental-ui/partials/*.hbs` files
3. Test the build to ensure images are loaded correctly
