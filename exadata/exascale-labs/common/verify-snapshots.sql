SET ECHO OFF

@@helpers.sql
@@config.sql

PROMPT PDB snapshot metadata

COLUMN con_id            FORMAT 999999
COLUMN snapshot_name      FORMAT A30
COLUMN snapshot_scn       FORMAT 999999999999
COLUMN snapshot_time      FORMAT A36
COLUMN full_snapshot_path FORMAT A100

PROMPT SQL/DDL:
PROMPT   SELECT con_id, snapshot_name, SNAPSHOT_SCN, SNAPSHOT_TIME, FULL_SNAPSHOT_PATH FROM dba_pdb_snapshots;

SELECT con_id,
       snapshot_name,
       SNAPSHOT_SCN,
       SNAPSHOT_TIME,
       FULL_SNAPSHOT_PATH
FROM   dba_pdb_snapshots;
