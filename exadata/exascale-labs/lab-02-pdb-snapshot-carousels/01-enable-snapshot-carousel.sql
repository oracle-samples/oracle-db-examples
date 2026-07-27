-- Enable the database-managed PDB snapshot carousel for SALES_MAIN.
--
-- This uses the built-in SNAPSHOT MODE EVERY clause. It does not manually
-- create or rotate named snapshots.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Enabling automated PDB snapshot carousel for &&MAIN_PDB

DECLARE
    l_container_name VARCHAR2(128);
    l_main_pdbs      NUMBER;
    l_instance_count NUMBER;
    l_rw_instances   NUMBER;
BEGIN
    SELECT sys_context('USERENV', 'CON_NAME')
    INTO   l_container_name
    FROM   dual;

    IF l_container_name <> '&&ROOT_CONTAINER' THEN
        raise_application_error(
            -20000,
            'This script must be run from &&ROOT_CONTAINER. Current container is ' ||
            l_container_name
        );
    END IF;

    SELECT COUNT(*)
    INTO   l_main_pdbs
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&MAIN_PDB');

    IF l_main_pdbs = 0 THEN
        raise_application_error(
            -20001,
            'Cannot enable snapshot carousel because &&MAIN_PDB does not exist.'
        );
    END IF;

    SELECT COUNT(*)
    INTO   l_instance_count
    FROM   gv$instance;

    SELECT COUNT(*)
    INTO   l_rw_instances
    FROM   gv$pdbs
    WHERE  name = UPPER('&&MAIN_PDB')
    AND    open_mode = 'READ WRITE';

    IF l_rw_instances <> l_instance_count THEN
        raise_application_error(
            -20002,
            '&&MAIN_PDB must be open READ WRITE on every RAC instance before enabling the carousel.'
        );
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to enable the automated snapshot carousel."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&MAIN_PDB;
PROMPT   ALTER PLUGGABLE DATABASE SET MAX_PDB_SNAPSHOTS = &&CAROUSEL_MAX_SNAPSHOTS;
PROMPT   ALTER PLUGGABLE DATABASE SNAPSHOT MODE EVERY &&CAROUSEL_INTERVAL;
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

ALTER SESSION SET CONTAINER = &&MAIN_PDB;

ALTER PLUGGABLE DATABASE SET MAX_PDB_SNAPSHOTS = &&CAROUSEL_MAX_SNAPSHOTS;

ALTER PLUGGABLE DATABASE SNAPSHOT MODE EVERY &&CAROUSEL_INTERVAL;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify the automated snapshot carousel mode."
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

PROMPT Automated PDB snapshot carousel enabled
