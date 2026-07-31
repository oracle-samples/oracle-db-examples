-- Create a hierarchical thin clone from an existing thin clone.
--
-- This demonstrates that a snapshot-copy PDB can be used as the source for
-- another snapshot-copy PDB, and that the child remains usable after the
-- immediate source clone is dropped.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Creating &&DEV_CLONE_CHILD from source clone &&DEV_CLONE_2

DECLARE
    l_container_name VARCHAR2(128);
    l_source_count   NUMBER;
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
    INTO   l_source_count
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&DEV_CLONE_2');

    IF l_source_count = 0 THEN
        raise_application_error(
            -20020,
            '&&DEV_CLONE_2 does not exist. Run 03-create-clones.sql before this script.'
        );
    END IF;
END;
/

PROMPT SQL/DDL:
PROMPT   If &&DEV_CLONE_CHILD exists:
PROMPT     DROP PLUGGABLE DATABASE &&DEV_CLONE_CHILD INCLUDING DATAFILES;
PROMPT
PROMPT Clusterware lifecycle before this SQL script:
PROMPT   ../common/manage-pdb-clusterware.sh stop-and-remove &&DEV_CLONE_CHILD

DEFINE LAB_PAUSE_MESSAGE = "Press Return to remove &&DEV_CLONE_CHILD if it already exists."
@@../common/&&LAB_PAUSE_SCRIPT

DECLARE
    l_child_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   l_child_count
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&DEV_CLONE_CHILD');

    IF l_child_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE &&DEV_CLONE_CHILD INCLUDING DATAFILES';
    END IF;
END;
/

PROMPT SQL/DDL:
PROMPT   CREATE PLUGGABLE DATABASE &&DEV_CLONE_CHILD
PROMPT     FROM &&DEV_CLONE_2
PROMPT     SNAPSHOT COPY;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to create &&DEV_CLONE_CHILD as a snapshot copy of the open &&DEV_CLONE_2 clone."
@@../common/&&LAB_PAUSE_SCRIPT

CREATE PLUGGABLE DATABASE &&DEV_CLONE_CHILD
    FROM &&DEV_CLONE_2
    SNAPSHOT COPY;

PROMPT Clusterware lifecycle after this SQL script:
PROMPT   ../common/manage-pdb-clusterware.sh ensure-and-start &&DEV_CLONE_CHILD
PROMPT Before dropping &&DEV_CLONE_2, run:
PROMPT   ../common/manage-pdb-clusterware.sh stop-and-remove &&DEV_CLONE_2
PROMPT Then run 05-drop-source-clone.sql to remove &&DEV_CLONE_2 and verify the child.

PROMPT Hierarchical clone creation complete
