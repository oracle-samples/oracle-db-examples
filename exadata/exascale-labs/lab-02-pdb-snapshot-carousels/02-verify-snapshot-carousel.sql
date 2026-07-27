-- Verify the database-managed PDB snapshot carousel state.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Verifying automated PDB snapshot carousel for &&MAIN_PDB

DEFINE LAB_PAUSE_MESSAGE = "Press Return to display snapshot carousel mode and interval."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   SELECT pdb_name, snapshot_mode, snapshot_interval / 60 AS snapshot_interval_hours
PROMPT   FROM   dba_pdbs
PROMPT   WHERE  pdb_name = '&&MAIN_PDB';
PROMPT
PROMPT   SELECT property_name, property_value
PROMPT   FROM   database_properties
PROMPT   WHERE  property_name = 'MAX_PDB_SNAPSHOTS';

SELECT pdb_name,
       snapshot_mode,
       snapshot_interval / 60 AS snapshot_interval_hours
FROM   dba_pdbs
WHERE  pdb_name = '&&MAIN_PDB';

ALTER SESSION SET CONTAINER = &&MAIN_PDB;

SELECT property_name,
       property_value
FROM   database_properties
WHERE  property_name = 'MAX_PDB_SNAPSHOTS';

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to display snapshots currently created by the database."
@@../common/&&LAB_PAUSE_SCRIPT

@@../common/verify-snapshots.sql

PROMPT Automated PDB snapshot carousel verification complete
