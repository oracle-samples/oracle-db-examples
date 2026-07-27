# Project TODOs

This file tracks repository-level TODOs that are not yet implemented or
validated. Keep short local TODO comments near the relevant code, but record the
project-level owner, context, and acceptance criteria here.

## Open

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
