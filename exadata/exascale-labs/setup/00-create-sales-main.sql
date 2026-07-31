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

PROMPT
PROMPT ============================================================
PROMPT Clusterware availability
PROMPT ============================================================
PROMPT
PROMPT Run this command from the operating system to create the PDB resource,
PROMPT start &&MAIN_PDB, and start its configured PDB service:
PROMPT   ../common/manage-pdb-clusterware.sh ensure-and-start &&MAIN_PDB

PROMPT
PROMPT ============================================================
PROMPT Final success summary
PROMPT ============================================================
PROMPT &&MAIN_PDB was created. Use the Clusterware lifecycle command above to
PROMPT make it available across its configured RAC placement before Lab 1.
PROMPT
