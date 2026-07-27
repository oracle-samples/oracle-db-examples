-- Create independent developer thin clones from the SALES_MAIN snapshot.
--
-- Run from CDB$ROOT after 01-create-snapshot.sql.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Creating developer clones from snapshot &&SNAPSHOT_NAME

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

DEFINE LAB_PAUSE_MESSAGE = "Press Return to create &&DEV_CLONE_1 and &&DEV_CLONE_2."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
PROMPT     FROM &&MAIN_PDB
PROMPT     USING SNAPSHOT &&SNAPSHOT_NAME
PROMPT     SNAPSHOT COPY;
PROMPT
PROMPT   CREATE PLUGGABLE DATABASE &&DEV_CLONE_2
PROMPT     FROM &&MAIN_PDB
PROMPT     USING SNAPSHOT &&SNAPSHOT_NAME
PROMPT     SNAPSHOT COPY;

CREATE PLUGGABLE DATABASE &&DEV_CLONE_1
    FROM &&MAIN_PDB
    USING SNAPSHOT &&SNAPSHOT_NAME
    SNAPSHOT COPY;

CREATE PLUGGABLE DATABASE &&DEV_CLONE_2
    FROM &&MAIN_PDB
    USING SNAPSHOT &&SNAPSHOT_NAME
    SNAPSHOT COPY;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to open both clones across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 OPEN READ WRITE INSTANCES = ALL;
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_2 OPEN READ WRITE INSTANCES = ALL;

DECLARE
    l_attempts CONSTANT PLS_INTEGER := 30;

    PROCEDURE open_pdb(p_pdb_name IN VARCHAR2) IS
    BEGIN
        FOR i IN 1 .. l_attempts LOOP
            BEGIN
                EXECUTE IMMEDIATE
                    'ALTER PLUGGABLE DATABASE ' ||
                    dbms_assert.simple_sql_name(UPPER(p_pdb_name)) ||
                    ' OPEN READ WRITE INSTANCES = ALL';
                dbms_output.put_line('Opened ' || UPPER(p_pdb_name) || ' across all RAC instances.');
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
    open_pdb('&&DEV_CLONE_1');
    open_pdb('&&DEV_CLONE_2');
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to save clone state across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_1 SAVE STATE INSTANCES = ALL;
PROMPT   ALTER PLUGGABLE DATABASE &&DEV_CLONE_2 SAVE STATE INSTANCES = ALL;

DECLARE
    l_attempts CONSTANT PLS_INTEGER := 30;

    PROCEDURE save_pdb_state(p_pdb_name IN VARCHAR2) IS
    BEGIN
        FOR i IN 1 .. l_attempts LOOP
            BEGIN
                EXECUTE IMMEDIATE
                    'ALTER PLUGGABLE DATABASE ' ||
                    dbms_assert.simple_sql_name(UPPER(p_pdb_name)) ||
                    ' SAVE STATE INSTANCES = ALL';
                dbms_output.put_line('Saved ' || UPPER(p_pdb_name) || ' state across all RAC instances.');
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
    save_pdb_state('&&DEV_CLONE_1');
    save_pdb_state('&&DEV_CLONE_2');
END;
/

-- TODO: Track Exadata Exascale physical sharing metrics in docs/todo.md.

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify clone state, services, and storage."
@@../common/&&LAB_PAUSE_SCRIPT

@@../common/verify-pdbs.sql
@@../common/verify-pdb-services.sql
@@../common/verify-storage.sql

PROMPT Developer clones created
