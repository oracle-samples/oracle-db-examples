-- Create the common SALES_MAIN PDB used by all Exadata Exascale labs.
--
-- Run from CDB$ROOT as a user with privileges to create pluggable databases.
-- Oracle Managed Files is assumed, so no file_name_convert clause is used.

@@../common/helpers.sql
@@../common/config.sql

SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT
PROMPT ============================================================
PROMPT Environment / context check
PROMPT ============================================================
PROMPT

DECLARE
    l_container_name VARCHAR2(128);
    l_existing_pdbs   NUMBER;
BEGIN
    SELECT sys_context('USERENV', 'CON_NAME')
    INTO   l_container_name
    FROM   dual;

    IF l_container_name <> 'CDB$ROOT' THEN
        raise_application_error(
            -20000,
            'This script must be run from CDB$ROOT. Current container is ' ||
            l_container_name
        );
    END IF;

    dbms_output.put_line('PASS: Connected to CDB$ROOT.');

    SELECT COUNT(*)
    INTO   l_existing_pdbs
    FROM   cdb_pdbs
    WHERE  pdb_name = UPPER('&&MAIN_PDB');

    IF l_existing_pdbs > 0 THEN
        raise_application_error(
            -20001,
            'Cannot create &&MAIN_PDB because a PDB named &&MAIN_PDB already exists. ' ||
            'This bootstrap script does not drop or recreate existing PDBs.'
        );
    END IF;

    dbms_output.put_line('PASS: &&MAIN_PDB does not already exist.');
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to create &&MAIN_PDB."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT
PROMPT ============================================================
PROMPT Password prompt
PROMPT ============================================================
PROMPT

ACCEPT PDB_ADMIN_PASSWORD CHAR PROMPT 'Enter password for &&APP_NAME._ADMIN: ' HIDE

PROMPT
PROMPT ============================================================
PROMPT Create &&MAIN_PDB
PROMPT ============================================================
PROMPT SQL/DDL:
PROMPT   CREATE PLUGGABLE DATABASE &&MAIN_PDB
PROMPT     ADMIN USER &&APP_NAME._ADMIN IDENTIFIED BY "<password>"
PROMPT     ROLES = (DBA);
PROMPT

CREATE PLUGGABLE DATABASE &&MAIN_PDB
    ADMIN USER &&APP_NAME._ADMIN IDENTIFIED BY "&&PDB_ADMIN_PASSWORD"
    ROLES = (DBA);

DEFINE LAB_PAUSE_MESSAGE = "Press Return to open &&MAIN_PDB across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT
PROMPT ============================================================
PROMPT Open &&MAIN_PDB
PROMPT ============================================================
PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&MAIN_PDB OPEN INSTANCES = ALL;
PROMPT

ALTER PLUGGABLE DATABASE &&MAIN_PDB OPEN INSTANCES = ALL;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to save &&MAIN_PDB state across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT
PROMPT ============================================================
PROMPT Save state across instances
PROMPT ============================================================
PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&MAIN_PDB SAVE STATE INSTANCES = ALL;
PROMPT

ALTER PLUGGABLE DATABASE &&MAIN_PDB SAVE STATE INSTANCES = ALL;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify &&MAIN_PDB."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT
PROMPT ============================================================
PROMPT Verify &&MAIN_PDB
PROMPT ============================================================
PROMPT

PROMPT GV$PDBS open state by RAC instance
PROMPT ============================================================
PROMPT

SELECT inst_id,
       con_id,
       name,
       open_mode,
       restricted,
       open_time
FROM   gv$pdbs
WHERE  name = UPPER('&&MAIN_PDB')
ORDER  BY inst_id;

PROMPT
PROMPT GV$SERVICES service placement by RAC instance
PROMPT ============================================================
PROMPT

SELECT inst_id,
       con_id,
       name,
       network_name,
       pdb
FROM   gv$services
WHERE  pdb = UPPER('&&MAIN_PDB')
ORDER  BY inst_id, name;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to show the final setup summary."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT
PROMPT ============================================================
PROMPT Final success summary
PROMPT ============================================================
PROMPT &&MAIN_PDB was created, opened, and saved across all RAC instances.
PROMPT The PDB is ready to use as the Lab 1 source database.
PROMPT
