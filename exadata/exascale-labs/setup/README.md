# Setup Scripts

This directory creates and validates the common starting environment used by the Exadata Exascale labs.

Run these scripts from `CDB$ROOT` as a user with privileges to create, open, close, and drop pluggable databases.

## Files

| File | Purpose |
|------|---------|
| `00-create-sales-main.sql` | Creates `SALES_MAIN`, opens it across all RAC instances, and saves state |
| `01-mask-data.sql` | Placeholder for site-specific data masking after refresh |
| `02-verify-environment.sql` | Runs shared verification checks from `common/` |
| `03-verify-exadata-software.sh` | Verifies Exadata System Software versions across database and storage servers using `dcli` |
| `99-reset-lab.sql` | Removes workshop PDBs and returns the CDB to a clean lab state |

## Usage

Create the starting PDB:

```sql
@00-create-sales-main.sql
```

Apply site-specific masking after loading or refreshing data into `SALES_MAIN`:

```sql
@01-mask-data.sql
```

Verify the environment:

```sql
@02-verify-environment.sql
```

Verify Exadata System Software from a central Exadata database server:

```bash
./03-verify-exadata-software.sh \
  --dbs-nodes dbnode01,dbnode02 \
  --cells-nodes cell01,cell02,cell03
```

The script uses `dcli` to run `dbmcli` on database servers and `cellcli` on storage servers. Supply either comma-separated node lists or existing `dcli` group files. No group-file location is assumed by default.

Use command-line options or environment variables when group files, users, or command paths differ:

```bash
DBS_GROUP=/path/to/dbs_group \
CELLS_GROUP=/path/to/cell_group \
DBS_USER=root \
CELLS_USER=celladmin \
./03-verify-exadata-software.sh
```

Reset the lab:

```sql
@99-reset-lab.sql
```

## Notes

- The labs assume Oracle RAC, Oracle Managed Files, and Exadata Exascale.
- Exadata System Software must be 24.1 or later on database and storage servers.
- `99-reset-lab.sql` drops the workshop PDBs and includes datafiles. It runs without interactive pauses.
- `01-mask-data.sql` intentionally contains no customer-specific masking rules.
- Add masking logic only after reviewing local data classification, privacy, and compliance requirements.
