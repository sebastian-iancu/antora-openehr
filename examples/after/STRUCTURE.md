# Example: Antora Structure (After Migration)

## Directory Tree

```
specifications-BASE/
├── antora.yml
├── modules/
│   ├── ROOT/
│   │   ├── nav.adoc
│   │   ├── pages/
│   │   │   └── index.adoc
│   │   ├── partials/
│   │   │   └── uml/
│   │   │       └── classes/
│   │   │           ├── LOCATABLE.adoc
│   │   │           ├── ARCHETYPED.adoc
│   │   │           └── PARTY_IDENTIFIED.adoc
│   │   └── images/
│   │       └── uml/
│   │           └── diagrams/
│   │               ├── BASE-foundation_types.svg
│   │               └── BASE-base_types.svg
│   ├── foundation_types/
│   │   ├── nav.adoc
│   │   ├── pages/
│   │   │   └── index.adoc
│   │   ├── partials/
│   │   │   ├── preface.adoc
│   │   │   ├── overview.adoc
│   │   │   ├── primitive_types.adoc
│   │   │   └── structures.adoc
│   │   └── images/
│   │       └── type-hierarchy.svg
│   └── base_types/
│       ├── nav.adoc
│       ├── pages/
│       │   └── index.adoc
│       └── partials/
│           ├── preface.adoc
│           └── identification.adoc
├── computable/
│   └── UML/
│       └── openEHR_UML-Base.mdzip
└── README.adoc
```

## Example File: antora.yml

```yaml
name: BASE
title: BASE Component
version: '1.1.0'
display_version: Release 1.1.0
start_page: ROOT:index.adoc
nav:
  - modules/ROOT/nav.adoc
  - modules/foundation_types/nav.adoc
  - modules/base_types/nav.adoc
asciidoc:
  attributes:
    component-title: BASE Component
```

## Example File: modules/ROOT/pages/index.adoc

```asciidoc
= BASE Component

Welcome to the BASE component of the openEHR specifications.

The BASE component provides foundational types and structures used throughout openEHR.

== Modules

* xref:foundation_types:index.adoc[Foundation Types]
* xref:base_types:index.adoc[Base Types]

== Overview

The BASE component consists of:

* Foundation types - basic types and structures
* Base types - identification, versioning, and change control
* UML definitions - formal class definitions

== Version Information

This is version {component-version} of the BASE specification.

== Related Components

* xref:RM::index.adoc[Reference Model (RM)]
* xref:AM::index.adoc[Archetype Model (AM)]
```

## Example File: modules/foundation_types/pages/index.adoc

```asciidoc
= Foundation Types
:page-aliases: foundation_types.adoc

[.lead]
This specification describes the foundation types used throughout openEHR.

include::partial$preface.adoc[]

include::partial$overview.adoc[]

== Primitive Types

include::partial$primitive_types.adoc[]

== Structures

include::partial$structures.adoc[]

== Class Definitions

=== LOCATABLE

include::ROOT:partial$uml/classes/LOCATABLE.adoc[]

=== ARCHETYPED

include::ROOT:partial$uml/classes/ARCHETYPED.adoc[]

== Diagrams

.Foundation Types Class Diagram
image::ROOT:uml/diagrams/BASE-foundation_types.svg[Foundation Types,800]
```

## Example File: modules/foundation_types/nav.adoc

```asciidoc
.Foundation Types
* xref:index.adoc[Overview]
** xref:index.adoc#_primitive_types[Primitive Types]
** xref:index.adoc#_structures[Structures]
** xref:index.adoc#_class_definitions[Class Definitions]
```

## Example File: modules/foundation_types/partials/preface.adoc

```asciidoc
== Preface

This specification describes the foundation types used throughout openEHR.

=== Purpose

The purpose of this specification is to define the basic types...

=== Status

This specification is in the {openehr-status} state...

=== Related Specifications

* xref:base_types:index.adoc[Base Types]
* xref:RM::index.adoc[Reference Model]
```

## Example File: modules/ROOT/partials/uml/classes/LOCATABLE.adoc

```asciidoc
=== LOCATABLE Class

[cols="1,3", options="header"]
|===
|Attribute |Description

|uid: `UID_BASED_ID` [0..1]
|Optional identifier for this object

|archetype_node_id: `String`
|Design-time archetype identifier

|name: `DV_TEXT`
|Runtime name of this fragment
|===

For more details, see xref:RM:ehr:locatable.adoc[LOCATABLE in RM].
```

## Key Differences from Before

1. **antora.yml** - Component descriptor at repository root
2. **modules/** - All content organized in modules
3. **ROOT module** - Contains shared UML content
4. **pages/** vs **partials/** - Clear distinction
5. **nav.adoc** - Explicit navigation structure
6. **Antora references** - `partial$`, `ROOT:`, component:module: format
7. **Cross-component links** - Can reference other components and versions

## Benefits

- Multi-version support out of the box
- Clear module boundaries
- Shared UML content in ROOT
- Cross-references with version awareness
- Better organization for large documentation sets
