# Exadata Exascale Labs

Hands-on labs demonstrating Oracle AI Database 26ai snapshot and cloning capabilities on Exadata Exascale.

## Overview

This repository accompanies the Exadata Exascale snapshots and clones blog series. It provides practical, end-to-end labs that demonstrate how to provision, manage, and refresh Oracle Multitenant databases using native Exadata Exascale snapshot and cloning capabilities.

Each lab uses the common setup environment while progressing from PDB thin cloning through operational workflows such as snapshot carousels and cross-CDB cloning.

## Target Environment

These labs assume the following environment:

- Oracle AI Database 26ai
- Exadata Exascale
- Exadata System Software 24.1 or later
- Oracle RAC (2 or more instances)
- Oracle Managed Files (OMF)
- SQLcl (recommended) or SQL*Plus
- SYSDBA privileges
- `srvctl` access for Clusterware-managed PDB resources and services

Unless otherwise stated, all commands are executed from `CDB$ROOT`.

## Repository Layout

```text
.
├── docs/
├── setup/
├── common/
├── lab-01-pdb-thin-clones/
├── lab-02-pdb-snapshot-carousels/
└── lab-03-cross-cdb-cloning/
```

### docs/

Reference documentation used throughout the labs.

### setup/

Creates the common starting point used by every lab.

### common/

Reusable helper and verification scripts shared by all labs.

### Labs

Each lab is self-contained and includes its own README describing objectives, prerequisites, execution steps, expected results, and cleanup.

| Lab | Topic |
|------|-------|
| Lab 01 | PDB Thin Clones |
| Lab 02 | PDB Snapshot Carousels |
| Lab 03 | Cross-CDB PDB Cloning |

## Lab Design Principles

These labs are written as production-quality examples rather than minimal demonstrations.

- RAC-first
- Explicit container context
- Verification after every step
- Host-level Exadata software checks before lab execution
- Reusable components in `common/`
- Consistent naming

## Roadmap

### Phase 1

- PDB Thin Clones
- PDB Snapshot Carousels
- Cross-CDB PDB Cloning

### Phase 2

Additional labs may include CDB-focused workflows and operational scenarios.

## Companion Blog Series

This repository accompanies the following blog series:

1. [Why Database Cloning Needed Reimagining](https://blogs.oracle.com/exadata/exadata-exascale-why-database-cloning-needed-reimagining)
2. [Exascale Snapshots and Clones: Core Concepts](https://blogs.oracle.com/exadata/exascale-snapshots-and-clones-core-concepts)
3. PDB Thin Clones: Fast Copies for Development and Test (upcoming)
4. PDB Snapshot Carousels (upcoming)
5. Cloning Between CDBs (upcoming)

## Publishing a Public Snapshot

Maintainers can publish a tagged, reviewable snapshot of these labs to the
public examples repository. See [Publishing a Public Snapshot](docs/publishing.md).
