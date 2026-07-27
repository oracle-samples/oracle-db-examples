-- Verify that DEV_ALEX and DEV_SARAH can diverge independently.
--
-- The script writes a small marker table into each clone and then reports the
-- clone-local rows. It does not modify SALES_MAIN or SALES_WEEKLY_SNAP.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Verifying clone independence

DECLARE
    l_container_name VARCHAR2(128);
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
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to write a marker row in &&DEV_CLONE_1."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&DEV_CLONE_1;
PROMPT   CREATE TABLESPACE &&APP_NAME._LAB_DATA DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE 100M;
PROMPT   ALTER USER &&APP_NAME._ADMIN QUOTA UNLIMITED ON &&APP_NAME._LAB_DATA;
PROMPT   INSERT INTO &&APP_NAME._ADMIN.lab01_clone_marker VALUES ('&&DEV_CLONE_1', ...);

ALTER SESSION SET CONTAINER = &&DEV_CLONE_1;

DECLARE
    PROCEDURE ensure_lab_tablespace IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_tablespaces
        WHERE  tablespace_name = '&&APP_NAME._LAB_DATA';

        IF l_count = 0 THEN
            EXECUTE IMMEDIATE
                'CREATE TABLESPACE &&APP_NAME._LAB_DATA ' ||
                'DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE 100M';
        END IF;

        EXECUTE IMMEDIATE
            'ALTER USER &&APP_NAME._ADMIN QUOTA UNLIMITED ON &&APP_NAME._LAB_DATA';
    END;

    PROCEDURE create_marker_table IS
        l_tablespace_name VARCHAR2(128);
    BEGIN
        BEGIN
            SELECT tablespace_name
            INTO   l_tablespace_name
            FROM   dba_tables
            WHERE  owner = UPPER('&&APP_NAME._ADMIN')
            AND    table_name = 'LAB01_CLONE_MARKER';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_tablespace_name := NULL;
        END;

        IF l_tablespace_name IS NOT NULL THEN
            IF l_tablespace_name = '&&APP_NAME._LAB_DATA' THEN
                RETURN;
            END IF;

            EXECUTE IMMEDIATE 'DROP TABLE &&APP_NAME._ADMIN.lab01_clone_marker PURGE';
        END IF;

        EXECUTE IMMEDIATE
            'CREATE TABLE &&APP_NAME._ADMIN.lab01_clone_marker ' ||
            '(clone_name VARCHAR2(128), marker_text VARCHAR2(200), created_at TIMESTAMP) ' ||
            'TABLESPACE &&APP_NAME._LAB_DATA';
    END;
BEGIN
    ensure_lab_tablespace;
    create_marker_table;

    EXECUTE IMMEDIATE 'DELETE FROM &&APP_NAME._ADMIN.lab01_clone_marker';
    EXECUTE IMMEDIATE
        'INSERT INTO &&APP_NAME._ADMIN.lab01_clone_marker ' ||
        'VALUES (''' || '&&DEV_CLONE_1' || ''', ''Alex clone local change'', SYSTIMESTAMP)';
    COMMIT;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to display marker rows in &&DEV_CLONE_1."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT Results from &&DEV_CLONE_1

SELECT clone_name,
       marker_text,
       created_at
FROM   &&APP_NAME._ADMIN.lab01_clone_marker
ORDER  BY created_at;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to write a marker row in &&DEV_CLONE_2."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;
PROMPT   ALTER SESSION SET CONTAINER = &&DEV_CLONE_2;
PROMPT   CREATE TABLESPACE &&APP_NAME._LAB_DATA DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE 100M;
PROMPT   ALTER USER &&APP_NAME._ADMIN QUOTA UNLIMITED ON &&APP_NAME._LAB_DATA;
PROMPT   INSERT INTO &&APP_NAME._ADMIN.lab01_clone_marker VALUES ('&&DEV_CLONE_2', ...);

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;
ALTER SESSION SET CONTAINER = &&DEV_CLONE_2;

DECLARE
    PROCEDURE ensure_lab_tablespace IS
        l_count NUMBER;
    BEGIN
        SELECT COUNT(*)
        INTO   l_count
        FROM   dba_tablespaces
        WHERE  tablespace_name = '&&APP_NAME._LAB_DATA';

        IF l_count = 0 THEN
            EXECUTE IMMEDIATE
                'CREATE TABLESPACE &&APP_NAME._LAB_DATA ' ||
                'DATAFILE SIZE 10M AUTOEXTEND ON NEXT 10M MAXSIZE 100M';
        END IF;

        EXECUTE IMMEDIATE
            'ALTER USER &&APP_NAME._ADMIN QUOTA UNLIMITED ON &&APP_NAME._LAB_DATA';
    END;

    PROCEDURE create_marker_table IS
        l_tablespace_name VARCHAR2(128);
    BEGIN
        BEGIN
            SELECT tablespace_name
            INTO   l_tablespace_name
            FROM   dba_tables
            WHERE  owner = UPPER('&&APP_NAME._ADMIN')
            AND    table_name = 'LAB01_CLONE_MARKER';
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                l_tablespace_name := NULL;
        END;

        IF l_tablespace_name IS NOT NULL THEN
            IF l_tablespace_name = '&&APP_NAME._LAB_DATA' THEN
                RETURN;
            END IF;

            EXECUTE IMMEDIATE 'DROP TABLE &&APP_NAME._ADMIN.lab01_clone_marker PURGE';
        END IF;

        EXECUTE IMMEDIATE
            'CREATE TABLE &&APP_NAME._ADMIN.lab01_clone_marker ' ||
            '(clone_name VARCHAR2(128), marker_text VARCHAR2(200), created_at TIMESTAMP) ' ||
            'TABLESPACE &&APP_NAME._LAB_DATA';
    END;
BEGIN
    ensure_lab_tablespace;
    create_marker_table;

    EXECUTE IMMEDIATE 'DELETE FROM &&APP_NAME._ADMIN.lab01_clone_marker';
    EXECUTE IMMEDIATE
        'INSERT INTO &&APP_NAME._ADMIN.lab01_clone_marker ' ||
        'VALUES (''' || '&&DEV_CLONE_2' || ''', ''Sarah clone local change'', SYSTIMESTAMP)';
    COMMIT;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to display marker rows in &&DEV_CLONE_2."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT Results from &&DEV_CLONE_2

SELECT clone_name,
       marker_text,
       created_at
FROM   &&APP_NAME._ADMIN.lab01_clone_marker
ORDER  BY created_at;

PROMPT SQL/DDL:
PROMPT   ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify clone state and storage after local writes."
@@../common/&&LAB_PAUSE_SCRIPT

@@../common/verify-pdbs.sql
@@../common/verify-storage.sql

-- TODO: Track changed-block space usage metrics in docs/todo.md.

PROMPT Clone independence verification complete
