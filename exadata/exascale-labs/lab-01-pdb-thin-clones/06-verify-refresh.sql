-- Verify DEV_ALEX after Clusterware has started the refreshed clone.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

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

@@../common/verify-pdbs.sql
@@../common/verify-pdb-services.sql
@@../common/verify-storage.sql

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
            dbms_output.put_line('PASS: Prior clone-local marker data is absent after refresh.');
        ELSE
            raise_application_error(
                -20020,
                'FAIL: Prior clone-local marker data remains after refresh.'
            );
        END IF;
    END IF;
END;
/

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

PROMPT Clone refresh verification complete
