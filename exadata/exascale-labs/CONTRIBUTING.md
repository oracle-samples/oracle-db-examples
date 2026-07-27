# Contributing to Exadata Exascale Labs

Thank you for helping build and refine these labs.

## Purpose

The labs in this repository are designed to be practical, RAC-aware, easy to read, and reusable across future Exadata Exascale demonstrations.

## Supported Environment

- Oracle AI Database 26ai
- Exadata Exascale
- Oracle RAC with two or more instances
- Oracle Managed Files enabled
- SQLcl preferred, SQL*Plus supported
- SYSDBA privileges
- Work performed from `CDB$ROOT` unless otherwise noted

## Working Principles

- RAC-first
- Explicit container context
- Verify every major step
- Reuse shared queries from `common/`
- Keep scripts self-documenting
- Use consistent naming

## Naming Conventions

| Object | Convention | Example |
|--------|------------|---------|
| Main PDB | `<APP>_MAIN` | `SALES_MAIN` |
| Snapshot | `<APP>_<PURPOSE>_SNAP` | `SALES_WEEKLY_SNAP` |
| Dev clone | `DEV_<NAME>` | `DEV_ALEX` |
| QA clone | `QA` | `QA` |
| CI clone | `CI_PIPELINE` | `CI_PIPELINE` |

## Script Style

- Prefer plain SQL and SQL*Plus-compatible syntax
- Avoid unnecessary procedural wrappers
- Keep comments brief and useful
- Make each script runnable on its own when possible
- Favor clarity over cleverness

## Verification Queries

Verification scripts should report useful state, not just raw dictionary output.

Examples include:

- PDB name
- open mode
- container ID
- snapshot presence
- storage usage
- service state when relevant
