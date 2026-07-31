-- Verify developer clones after their Clusterware PDB resources and services start.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

@@../common/verify-pdbs.sql
@@../common/verify-pdb-services.sql
@@../common/verify-storage.sql

PROMPT Developer clone verification complete
