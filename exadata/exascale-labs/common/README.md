# Common Scripts

This directory contains reusable configuration, formatting, and verification scripts shared by all Exadata Exascale labs.

## Files

| File | Purpose |
|------|---------|
| `config.sql` | Shared object names used across the workshop |
| `manage-pdb-clusterware.sh` | Creates, starts, stops, verifies, and removes RAC PDB resources and PDB services with `srvctl` |
| `helpers.sql` | SQLcl and SQL*Plus formatting used by the lab scripts |
| `verify-pdbs.sql` | Displays PDB open state on every RAC instance and summarizes read-write placement |
| `verify-pdb-services.sql` | Displays PDB services on every RAC instance and summarizes service placement |
| `verify-snapshots.sql` | Displays snapshot-related PDB metadata for the workshop PDBs |
| `verify-storage.sql` | Summarizes allocated and autoextend storage by PDB |
| `verify-datafiles.sql` | Lists PDB datafiles, tablespaces, sizes, and OMF paths |
| `disable-snapshot-carousel.sql` | Disables automated snapshot mode for the configured source PDB |
| `drop-snapshot.sql` | Drops the configured named PDB snapshot from the configured source PDB |
| `skip-snapshot-carousel.sql` | Reports that automated snapshot mode cleanup was skipped |
| `skip-snapshot.sql` | Reports that a configured named PDB snapshot was not found |
| `pause.sql` | Waits for Return during interactive walkthroughs |
| `pause-off.sql` | Prints pause text without waiting for non-interactive runs |

## Usage

Most lab scripts begin by loading the shared formatting and configuration files:

```sql
@@../common/helpers.sql
@@../common/config.sql
```

Verification checks can then be run as needed:

```sql
@@../common/verify-pdbs.sql
@@../common/verify-pdb-services.sql
@@../common/verify-snapshots.sql
@@../common/verify-storage.sql
@@../common/verify-datafiles.sql
```

Use the Clusterware helper after setting `CDB_UNIQUE_NAME` in `config.sql`:

```bash
./manage-pdb-clusterware.sh ensure-and-start SALES_MAIN
./manage-pdb-clusterware.sh verify SALES_MAIN
./manage-pdb-clusterware.sh stop-and-remove DEV_ALEX
```

For automated environments, `CDB_UNIQUE_NAME` can be supplied as an environment
variable instead of editing `config.sql`.

The default `RAC_PDB_PLACEMENT=AUTO` is compatible with CDBs that already have
PDB resources created without `-cardinality`. Set the service placement with
`RAC_SERVICE_PREFERRED`, either in `config.sql` or as an environment variable.
Use `RAC_PDB_PLACEMENT=ALL` only for CDBs already using cardinality-based PDB
resources.

## Notes

- The labs assume Oracle RAC, so the verification queries use `GV$` views where instance awareness matters.
- The Clusterware helper uses the PDB and service names in `config.sql`. It owns routine PDB availability and service placement; SQL scripts retain snapshot, clone, refresh, and drop DDL.
- The labs assume Oracle Managed Files, so datafile verification reports generated file names rather than requiring user-supplied paths.
- Commands are expected to run from `CDB$ROOT` unless a lab explicitly says otherwise.
- The scripts are written for SQLcl while remaining readable in SQL*Plus.
- `LAB_PAUSE_SCRIPT` in `config.sql` controls walkthrough pauses. Use `pause.sql` to wait for Return, or `pause-off.sql` to print the pause text without waiting.
- Demo scripts keep command echo disabled and print the main SQL/DDL for each major step explicitly.
