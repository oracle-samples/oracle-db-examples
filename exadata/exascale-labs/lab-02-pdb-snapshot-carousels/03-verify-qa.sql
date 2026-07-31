-- Verify QA after its Clusterware PDB resource and service start.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

@@../common/verify-pdbs.sql
@@../common/verify-pdb-services.sql
@@../common/verify-snapshots.sql
@@../common/verify-storage.sql

PROMPT QA clone verification complete
