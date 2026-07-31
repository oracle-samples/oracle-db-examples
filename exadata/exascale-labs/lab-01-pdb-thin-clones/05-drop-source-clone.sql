-- Remove the source clone after the hierarchical child is Clusterware-managed.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Clusterware lifecycle before this SQL script:
PROMPT   ../common/manage-pdb-clusterware.sh stop-and-remove &&DEV_CLONE_2
PROMPT
PROMPT SQL/DDL:
PROMPT   DROP PLUGGABLE DATABASE &&DEV_CLONE_2 INCLUDING DATAFILES;

DECLARE
    l_container_name VARCHAR2(128);
    l_count          NUMBER;
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
    WHERE  pdb_name = UPPER('&&DEV_CLONE_2');

    IF l_count > 0 THEN
        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE &&DEV_CLONE_2 INCLUDING DATAFILES';
    END IF;
END;
/

ALTER SESSION SET CONTAINER = &&DEV_CLONE_CHILD;

DECLARE
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

    INSERT INTO &&APP_NAME._ADMIN.lab01_clone_marker
    VALUES ('&&DEV_CLONE_CHILD', 'Child clone local change after source drop', SYSTIMESTAMP);
END;
/

COMMIT;

ALTER SESSION SET CONTAINER = &&ROOT_CONTAINER;

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
