# Project TODOs

This file tracks repository-level TODOs that are not yet implemented or
validated. Keep short local TODO comments near the relevant code, but record the
project-level owner, context, and acceptance criteria here.

## Open

### Manage RAC PDB availability with Clusterware resources and services

- Area: RAC lifecycle management
- References:
  - `AGENTS.md`
  - `common/config.sql`
  - `lab-01-pdb-thin-clones/00-run-lab.sh`
  - `lab-02-pdb-snapshot-carousels/00-run-lab.sh`
  - setup, Lab 01, and Lab 02 PDB open, close, refresh, and cleanup scripts
- Context: the labs currently use `ALTER PLUGGABLE DATABASE ... INSTANCES = ALL`
  and `SAVE STATE` to manage PDB availability across RAC. Adopt
  Clusterware-managed PDB resources and PDB services for routine availability,
  while retaining SQL for snapshot, clone, and drop DDL.
- Done when:
  - Shared configuration supplies the CDB, SRVCTL, PDB service, and RAC
    placement details required by the labs.
  - Runners and manual workflows use idempotent `srvctl` helpers to create,
    start, stop, verify, and remove PDB services and PDB resources as needed.
  - Clone creation, refresh, and cleanup safely handle absent, stopped, and
    partially created PDB services.
  - Verification reports both Clusterware PDB/service status and RAC service
    placement.
  - Database-backed RAC tests validate service placement, PDB reopen behavior,
    clone recreation, and cleanup.
  - Documentation and `AGENTS.md` distinguish routine Clusterware lifecycle
    management from SQL DDL that specifically requires
    `ALTER PLUGGABLE DATABASE`.

### Add sudo support for database-server software checks

- Area: setup pre-flight
- References: `setup/03-verify-exadata-software.sh`
- Context: the script currently uses `dcli` to connect to database servers as
  `root` and run `dbmcli`. Support an unprivileged SSH user that can use `sudo`
  for the required database-server command.
- Done when: the script offers an explicit, documented option for sudo-based
  database-server checks, preserves the existing root-based behavior, and
  returns a clear error when the configured user lacks the required sudo access.

### Add Exadata Exascale physical storage metrics

- Area: common verification
- References:
  - `common/verify-storage.sql`
  - `lab-01-pdb-thin-clones/03-create-clones.sql`
  - `lab-01-pdb-thin-clones/04-verify-independence.sql`
  - `lab-01-pdb-thin-clones/06-refresh-clone.sql`
  - `lab-01-pdb-thin-clones/README.md`
- Context: current storage verification reports logical datafile allocation from
  `CDB_DATA_FILES`. It does not yet report Exadata Exascale physical sharing,
  sparse allocation, clone dependency metadata, or changed-block usage.
- Done when: supported Oracle AI Database 26ai / Exadata Exascale views or
  commands are identified and the shared verification scripts report physical
  storage savings and changed-block growth for snapshot-copy clones.
