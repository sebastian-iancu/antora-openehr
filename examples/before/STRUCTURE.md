# Example: Current Structure (Before Migration)

## Directory Tree

```
specifications-BASE/
├── docs/
│   ├── foundation_types/
│   │   ├── master.adoc
│   │   ├── master01-preface.adoc
│   │   ├── master02-overview.adoc
│   │   ├── master03-primitive_types.adoc
│   │   ├── master04-structures.adoc
│   │   └── images/
│   │       └── type-hierarchy.svg
│   ├── base_types/
│   │   ├── master.adoc
│   │   ├── master01-preface.adoc
│   │   └── master02-identification.adoc
│   └── UML/
│       ├── classes/
│       │   ├── LOCATABLE.adoc
│       │   ├── ARCHETYPED.adoc
│       │   └── PARTY_IDENTIFIED.adoc
│       └── diagrams/
│           ├── BASE-foundation_types.svg
│           └── BASE-base_types.svg
├── computable/
│   └── UML/
│       └── openEHR_UML-Base.mdzip
└── README.adoc
```

## Example File: docs/foundation_types/master.adoc

```asciidoc
= Foundation Types
:doctype: book
:toc: left
:toclevels: 3
:numbered:
:source-highlighter: rouge

include::master01-preface.adoc[]

include::master02-overview.adoc[]

== Primitive Types

include::master03-primitive_types.adoc[]

== Structures

include::master04-structures.adoc[]

== Class Definitions

=== LOCATABLE

include::../../UML/classes/LOCATABLE.adoc[]

=== ARCHETYPED

include::../../UML/classes/ARCHETYPED.adoc[]

== Diagrams

.Foundation Types Class Diagram
image::../../UML/diagrams/BASE-foundation_types.svg[Foundation Types]
```

## Example File: docs/foundation_types/master01-preface.adoc

```asciidoc
== Preface

This specification describes the foundation types used throughout openEHR.

=== Purpose

The purpose of this specification is to define the basic types...

=== Status

This specification is in the {openehr-status} state...
```

## Example File: docs/UML/classes/LOCATABLE.adoc

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
```

This structure has been used since the early days of openEHR specifications.
The migration will transform this to Antora-compatible structure.
