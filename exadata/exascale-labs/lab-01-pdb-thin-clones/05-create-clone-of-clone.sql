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
PROMPT     ALTER PLUGGABLE DATABASE &&DEV_CLONE_CHILD CLOSE IMMEDIATE INSTANCES = ALL;
PROMPT     DROP PLUGGABLE DATABASE &&DEV_CLONE_CHILD INCLUDING DATAFILES;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to remove &&DEV_CLONE_CHILD if it already exists."
@@../common/&&LAB_PAUSE_SCRIPT

DECLARE
    l_child_count NUMBER;
    l_open_count  NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   l_child_count
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&DEV_CLONE_CHILD');

    IF l_child_count > 0 THEN
        SELECT COUNT(*)
        INTO   l_open_count
        FROM   gv$pdbs
        WHERE  name = UPPER('&&DEV_CLONE_CHILD')
        AND    open_mode <> 'MOUNTED';

        IF l_open_count > 0 THEN
            EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&DEV_CLONE_CHILD CLOSE IMMEDIATE INSTANCES = ALL';
        END IF;

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

PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_CHILD OPEN READ WRITE INSTANCES = ALL;
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_CHILD SAVE STATE INSTANCES = ALL;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to open and save &&DEV_CLONE_CHILD across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

DECLARE
    l_attempts CONSTANT PLS_INTEGER := 30;

    PROCEDURE run_with_retry(p_sql IN VARCHAR2, p_success_message IN VARCHAR2) IS
    BEGIN
        FOR i IN 1 .. l_attempts LOOP
            BEGIN
                EXECUTE IMMEDIATE p_sql;
                dbms_output.put_line(p_success_message);
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
BEGIN
    run_with_retry(
        'ALTER PLUGGABLE DATABASE &&DEV_CLONE_CHILD OPEN READ WRITE INSTANCES = ALL',
        'Opened &&DEV_CLONE_CHILD across all RAC instances.'
    );
    run_with_retry(
        'ALTER PLUGGABLE DATABASE &&DEV_CLONE_CHILD SAVE STATE INSTANCES = ALL',
        'Saved &&DEV_CLONE_CHILD state across all RAC instances.'
    );
END;
/

PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_2 CLOSE IMMEDIATE INSTANCES = ALL;
PROMPT   DROP PLUGGABLE DATABASE &&DEV_CLONE_2 INCLUDING DATAFILES;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to drop source clone &&DEV_CLONE_2."
@@../common/&&LAB_PAUSE_SCRIPT

ALTER PLUGGABLE DATABASE &&DEV_CLONE_2 CLOSE IMMEDIATE INSTANCES = ALL;
DROP PLUGGABLE DATABASE &&DEV_CLONE_2 INCLUDING DATAFILES;

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&DEV_CLONE_CHILD;
PROMPT   INSERT INTO &&APP_NAME._ADMIN.lab01_clone_marker VALUES ('&&DEV_CLONE_CHILD', ...);
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to write a marker row in &&DEV_CLONE_CHILD after &&DEV_CLONE_2 is dropped."
@@../common/&&LAB_PAUSE_SCRIPT

ALTER SESSION SET CONTAINER = &&DEV_CLONE_CHILD;

DECLARE
    PROCEDURE ensure_marker_table IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_tables
        WHERE  owner = UPPER('&&APP_NAME._ADMIN')
        AND    table_name = 'LAB01_CLONE_MARKER';

        IF l_count = 0 THEN
            EXECUTE IMMEDIATE
                'CREATE TABLE &&APP_NAME._ADMIN.lab01_clone_marker ' ||
                '(clone_name VARCHAR2(128), marker_text VARCHAR2(200), created_at TIMESTAMP)';
        END IF;
    END;
BEGIN
    ensure_marker_table;

    EXECUTE IMMEDIATE
        'INSERT INTO &&APP_NAME._ADMIN.lab01_clone_marker ' ||
        'VALUES (''' || '&&DEV_CLONE_CHILD' || ''', ''Child clone local change after source drop'', SYSTIMESTAMP)';
    COMMIT;
END;
/

PROMPT Marker rows visible in &&DEV_CLONE_CHILD

SELECT clone_name,
       marker_text,
       created_at
FROM   &&APP_NAME._ADMIN.lab01_clone_marker
ORDER  BY created_at;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify &&DEV_CLONE_CHILD remains after &&DEV_CLONE_2 is dropped."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT Clone hierarchy status

WITH expected_pdbs AS (
    SELECT '&&DEV_CLONE_2' AS pdb_name FROM dual
    UNION ALL
    SELECT '&&DEV_CLONE_CHILD' AS pdb_name FROM dual
)
SELECT e.pdb_name,
       CASE
           WHEN p.pdb_name IS NULL THEN 'DROPPED'
           ELSE p.status
       END AS dictionary_status
FROM   expected_pdbs e
       LEFT JOIN dba_pdbs p
         ON p.pdb_name = e.pdb_name
ORDER  BY e.pdb_name;

@@../common/verify-pdbs.sql
@@../common/verify-storage.sql

PROMPT Hierarchical clone verification complete
