# Prerequisites

This document describes the environment and assumptions used throughout the Exadata Exascale Labs.

All labs in this repository have been developed and tested against the environment described below.

## Software Requirements

The labs assume the following software versions.

| Component | Requirement |
|----------|-------------|
| Database | Oracle AI Database 26ai |
| Platform | Exadata Exascale |
| Exadata System Software | **24.1 or later** |
| Architecture | Oracle Multitenant |
| Cluster | Oracle RAC (2 or more instances) |
| Client | SQLcl (recommended) or SQL*Plus |

> **Note**
>
> Exadata snapshot and cloning capabilities require **Exadata System Software 24.1 or later**. These labs are developed and validated using the software versions listed in the **Tested Environment** section below.

## Environment Requirements

The following database and environment configuration is assumed throughout the labs.

- Oracle Managed Files (OMF) enabled
- Container Database (CDB) already created
- SYSDBA privileges available
- Ability to create and drop PDBs
- Ability to create snapshots and thin clones
- Exadata Exascale storage configured and available
- Passwordless SSH equivalence from the central database server to each database server as `root`, and to each storage server as `celladmin` or `root`

## Starting Environment

The setup scripts supplied with this repository create the common starting point used by every lab.

Once setup is complete, the environment contains:

- `SALES_MAIN`
  - A development PDB refreshed from production.
  - Sensitive data has been masked to protect security and privacy.
  - Serves as the source for all subsequent snapshot and clone operations.

## Repository Assumptions

### Oracle RAC

Examples assume Oracle RAC.

Where appropriate:

- `GV$` views are used instead of `V$`
- `INSTANCES=ALL` is specified when opening and closing PDBs
- Examples are written to operate correctly across all cluster instances

### Container Context

Unless otherwise stated, commands are executed from `CDB$ROOT`.

Scripts explicitly change container context where required.

### Oracle Managed Files

Examples assume Oracle Managed Files.

Storage locations are intentionally omitted unless they are relevant to the feature being demonstrated.

### Verification

Every significant operation is followed by a verification step.

## Before You Begin

Before running a lab, verify that:

- Oracle RAC is healthy.
- All database instances are running.
- The target CDB is open.
- Exadata System Software is 24.1 or later on database and storage servers.
- Exadata Exascale storage is available.
- `SALES_MAIN` exists, or execute the setup scripts.
- You are connected as a user with the required administrative privileges.

## Exadata Software Version Check

Use the setup pre-flight script to verify Exadata System Software from a central Exadata database server:

```bash
cd setup
./03-verify-exadata-software.sh \
  --dbs-nodes dbnode01,dbnode02 \
  --cells-nodes cell01,cell02,cell03
```

The script uses `dcli` to run `dbmcli` across database servers and `cellcli` across storage servers. It fails if any reported version is below 24.1. It requires passwordless SSH equivalence from the central database server: `root` for database servers and `celladmin` for storage servers by default. Use `--cells-user root` when storage-server SSH equivalence is configured for `root` instead.

Supply either comma-separated node lists or existing `dcli` group files. No group-file location is assumed by default. For example:

```bash
DBS_GROUP=/path/to/dbs_group \
CELLS_GROUP=/path/to/cell_group \
./03-verify-exadata-software.sh
```

## Tested Environment

The labs are developed and validated using the following software versions.

| Component | Version |
|----------|---------|
| Oracle AI Database | 23.26.2 (Oracle AI Database 26ai Release Update) |
| Oracle Grid Infrastructure | 26.1.0.0.0 |
| Exadata System Software | 26.1.0.0.0 |
| Exadata Storage Server Software | 26.1.0.0.0 |
| SQLcl | 26.1 |
