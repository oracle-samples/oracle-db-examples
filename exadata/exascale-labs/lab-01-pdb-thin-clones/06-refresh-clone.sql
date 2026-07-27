-- Refresh DEV_ALEX from the stable weekly snapshot.
--
-- Snapshot-based clones are independent read-write PDBs. This lab refreshes
-- the clone by dropping it and recreating it from the named SALES_MAIN snapshot.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Refreshing &&DEV_CLONE_1 from &&SNAPSHOT_NAME
PROMPT SQL/DDL:
PROMPT   If &&DEV_CLONE_1 exists:
PROMPT     ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 CLOSE IMMEDIATE INSTANCES = ALL;
PROMPT     DROP PLUGGABLE DATABASE &&DEV_CLONE_1 INCLUDING DATAFILES;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to close and drop &&DEV_CLONE_1 if it exists."
@@../common/&&LAB_PAUSE_SCRIPT

DECLARE
    l_container_name VARCHAR2(128);
    l_count          NUMBER;
    l_open_count     NUMBER;
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
    INTO   l_count
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&DEV_CLONE_1');

    IF l_count > 0 THEN
        SELECT COUNT(*)
        INTO   l_open_count
        FROM   gv$pdbs
        WHERE  name = UPPER('&&DEV_CLONE_1')
        AND    open_mode <> 'MOUNTED';

        IF l_open_count > 0 THEN
            EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 CLOSE IMMEDIATE INSTANCES = ALL';
        END IF;

        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE &&DEV_CLONE_1 INCLUDING DATAFILES';
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to recreate &&DEV_CLONE_1 from snapshot &&SNAPSHOT_NAME."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
PROMPT     FROM &&MAIN_PDB
PROMPT     USING SNAPSHOT &&SNAPSHOT_NAME
PROMPT     SNAPSHOT COPY;

CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
    FROM &&MAIN_PDB
    USING SNAPSHOT &&SNAPSHOT_NAME
    SNAPSHOT COPY;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to open &&DEV_CLONE_1 across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 OPEN READ WRITE INSTANCES = ALL;

DECLARE
    l_attempts CONSTANT PLS_INTEGER := 30;
BEGIN
    FOR i IN 1 .. l_attempts LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 OPEN READ WRITE INSTANCES = ALL';
            dbms_output.put_line('Opened &&DEV_CLONE_1 across all RAC instances.');
            RETURN;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -65011 AND i < l_attempts THEN
                    dbms_session.sleep(1);
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to save &&DEV_CLONE_1 state across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 SAVE STATE INSTANCES = ALL;

DECLARE
    l_attempts CONSTANT PLS_INTEGER := 30;
BEGIN
    FOR i IN 1 .. l_attempts LOOP
        BEGIN
            EXECUTE IMMEDIATE
                'ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 SAVE STATE INSTANCES = ALL';
            dbms_output.put_line('Saved &&DEV_CLONE_1 state across all RAC instances.');
            RETURN;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = -65011 AND i < l_attempts THEN
                    dbms_session.sleep(1);
                ELSE
                    RAISE;
                END IF;
        END;
    END LOOP;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify refreshed clone state and storage."
@@../common/&&LAB_PAUSE_SCRIPT

@@../common/verify-pdbs.sql
@@../common/verify-storage.sql

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify that clone-local marker data was reset."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&DEV_CLONE_1;
PROMPT   Verify that the clone-local marker table or prior marker row is absent.

ALTER SESSION SET CONTAINER = &&DEV_CLONE_1;

DECLARE
    l_marker_table_count NUMBER;
    l_marker_row_count   NUMBER := 0;
BEGIN
    SELECT COUNT(*)
    INTO   l_marker_table_count
    FROM   dba_tables
    WHERE  owner = UPPER('&&APP_NAME._ADMIN')
    AND    table_name = 'LAB01_CLONE_MARKER';

    IF l_marker_table_count = 0 THEN
        dbms_output.put_line(
            'PASS: Clone-local marker table is absent after refresh. ' ||
            '&&DEV_CLONE_1 matches the snapshot baseline.'
        );
    ELSE
        EXECUTE IMMEDIATE
            'SELECT COUNT(*) FROM &&APP_NAME._ADMIN.lab01_clone_marker ' ||
            'WHERE clone_name = :1 AND marker_text = :2'
        INTO l_marker_row_count
        USING '&&DEV_CLONE_1', 'Alex clone local change';

        IF l_marker_row_count = 0 THEN
            dbms_output.put_line(
                'PASS: Prior clone-local marker data is absent after refresh.'
            );
        ELSE
            raise_application_error(
                -20020,
                'FAIL: Prior clone-local marker data remains after refresh.'
            );
        END IF;
    END IF;
END;
/

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

PROMPT Clone refresh complete
