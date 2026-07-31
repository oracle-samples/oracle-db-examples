# AI Agent Guidance

This repository contains hands-on Exadata Exascale labs for Oracle AI Database
26ai. It accompanies the Exadata Exascale snapshot and clone blog series, and it
also serves as a standalone workshop for provisioning, verifying, refreshing, and
cleaning up snapshot and thin clone workflows.

Use this file as guidance for AI coding assistants working in the repository.
It complements `CONTRIBUTING.md`; do not treat it as a replacement for the
repository documentation.

## 1. Repository Overview

The labs demonstrate Oracle Multitenant snapshot and cloning workflows on
Exadata Exascale. The workshop starts from a refreshed and masked development
PDB, `SALES_MAIN`, and uses it as the source for snapshots and read-write thin
clones.

The repository is organized as a progressive workshop. Each lab builds on the
common environment and preserves the same naming conventions, verification
style, and operational assumptions. The content should be useful both as a
companion to the blog series and as a practical, repeatable lab set.

## 2. Project Philosophy

Prioritize:

- Technical accuracy.
- Reproducibility.
- Readability.
- Real-world operational practices.

Examples should resemble Oracle engineering documentation rather than minimal
demos. Prefer explicit setup, verification, and cleanup over terse examples that
hide operational context.

## 3. Environment Assumptions

Unless a lab states otherwise, assume:

- Oracle AI Database 26ai.
- Exadata Exascale.
- Exadata System Software 24.1 or later.
- Oracle RAC with two or more instances.
- Oracle Managed Files enabled.
- SQLcl preferred, with SQL*Plus compatibility where practical.
- SYSDBA privileges.
- Commands run from `CDB$ROOT` unless explicitly changed.

Do not invent environment requirements or Oracle syntax. If behavior is unclear
from the existing documentation or product documentation, leave a TODO marker
instead of guessing.

## 4. Coding Standards

Follow the conventions already established in `README.md`,
`CONTRIBUTING.md`, `docs/prerequisites.md`, and `docs/architecture.md`.

- Prefer `GV$` views over `V$` views where RAC awareness is required.
- Use `INSTANCES=ALL` only for exceptional SQL DDL that explicitly requires a
  cluster-wide PDB state change. Routine availability is Clusterware-managed.
- Use `common/manage-pdb-clusterware.sh` for routine PDB availability and PDB
  service lifecycle management. It creates, starts, stops, verifies, and
  removes Clusterware PDB resources and services using `srvctl`.
- Reserve `ALTER PLUGGABLE DATABASE` for snapshot, clone, refresh, and drop
  DDL. Do not use it for routine PDB open, close, or saved-state management.
- Always explicitly set container context before container-specific work.
- Do not hardcode object names when `common/config.sql` provides them.
- Reuse scripts from `common/` wherever possible.
- Keep SQL readable and operationally direct.
- Keep comments concise and useful.

Avoid unnecessary procedural wrappers. A script should be easy for a DBA or lab
participant to inspect, run, and troubleshoot.

## 5. Documentation Standards

Every lab includes a README that describes its objective, prerequisites,
execution steps, expected results, and cleanup. Keep documentation synchronized
with the SQL and shell scripts it describes.

- Every significant operation needs a verification step.
- Documentation should explain why an operation matters, not only how to run it.
- Use Mermaid diagrams for architecture and workflow explanations.
- SVG artwork under `docs/images/` may supplement Mermaid diagrams when a presentation-quality illustration is needed.
- Link to existing docs instead of duplicating large sections of them.

## 6. Repository Structure

- `setup/`: Creates and resets the common starting environment, including
  `SALES_MAIN` and prerequisite checks.
- `common/`: Shared configuration, helper scripts, and reusable verification
  queries.
- `lab-*/`: Self-contained labs for specific Exadata Exascale workflows.
- `docs/`: Reference architecture, prerequisites, and supporting documentation.

Preserve this structure when adding new labs or shared utilities. Add shared
logic to `common/` only when it is reusable across labs.

## 7. SQL Guidelines

Write SQL for SQLcl compatibility and keep SQL*Plus compatibility where
practical.

- Prefer reusable verification scripts over one-off dictionary queries.
- Avoid SQL*Plus-specific shortcuts when a clear portable form is practical.
- Do not invent Oracle features, clauses, or undocumented syntax.
- Use existing substitution variables and configuration patterns.
- Leave TODO markers for uncertain behavior or product details that need
  confirmation.
- Track project-level TODOs in `docs/todo.md`. Keep inline TODO comments short
  and point them at `docs/todo.md` when they represent backlog items rather
  than immediate local implementation notes.
- Source PDBs or source clones do not need to be opened read-only before
  creating a snapshot-copy clone.
- Prefer direct SQL for PDB snapshot DDL when practical. Avoid hiding snapshot
  drop operations inside PL/SQL `EXECUTE IMMEDIATE` blocks because privilege
  behavior can differ from top-level SQL.
- Cleanup and reset scripts must be idempotent. Missing PDBs and missing
  snapshots should be reported and skipped cleanly.
- SQLcl is preferred, but hidden `ACCEPT ... HIDE` prompts are not reliable for
  piped non-interactive setup runs.

Verification scripts should report meaningful lab state, such as PDB name, open
mode, container ID, snapshot presence, storage usage, and service state where
relevant.

## 8. Working With This Repository

Before making changes, read the relevant existing documentation and nearby
scripts. Make focused changes that preserve the progressive workshop flow.

- Avoid unrelated refactoring.
- Preserve existing naming conventions.
- Keep README steps, script names, and verification output consistent.
- Update documentation and SQL together when behavior changes.
- Prefer small, reviewable changes over broad rewrites.

When adding or changing a lab, ensure the setup assumptions, execution steps,
verification steps, and cleanup path remain clear.

## 9. Validation

Before considering work complete, check that:

- Links reference existing files.
- Scripts reference existing files and shared configuration correctly.
- README files remain consistent with script behavior.
- No duplicated logic has been introduced where `common/` already provides a
  reusable script.
- Container context and RAC behavior are explicit where required.
- Shell runners that invoke SQLcl or SQL*Plus should send an explicit
  `EXIT SQL.SQLCODE` after each SQL script so automation does not hang in an
  interactive SQL prompt and still propagates SQL failures.

If executable validation is not possible in the current environment, document
what was reviewed and what still requires database-backed testing.

## 10. Future Scope

Future labs are expected to cover:

- CDB thin clones.
- Additional Exadata Exascale operational workflows.

When preparing future content, keep the same standards for reproducibility,
RAC-aware operations, verification, and cleanup.
