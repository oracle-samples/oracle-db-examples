-- Create a QA thin clone from the newest available snapshot for SALES_MAIN.
--
-- Run this after the database has created at least one automated snapshot for
-- SALES_MAIN.

@@../common/helpers.sql
@@../common/config.sql

WHENEVER SQLERROR EXIT SQL.SQLCODE

PROMPT Creating &&QA_PDB from the latest available snapshot for &&MAIN_PDB

COLUMN latest_snapshot NEW_VALUE LATEST_CAROUSEL_SNAPSHOT NOPRINT

SELECT snapshot_name AS latest_snapshot
FROM   (
           SELECT snapshot_name,
                  snapshot_scn
           FROM   dba_pdb_snapshots
           WHERE  con_name = '&&MAIN_PDB'
           ORDER  BY snapshot_scn DESC
       )
WHERE  ROWNUM = 1;

DECLARE
    l_latest_snapshot VARCHAR2(128) := '&&LATEST_CAROUSEL_SNAPSHOT';
BEGIN
    IF l_latest_snapshot IS NULL OR l_latest_snapshot LIKE '&&%' THEN
        raise_application_error(
            -20001,
            'No snapshots exist for &&MAIN_PDB yet. Wait for an interval snapshot or capture a precise post-refresh snapshot, then retry.'
        );
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to remove &&QA_PDB if it already exists."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   If &&QA_PDB exists:
PROMPT     ALTER PLUGGABLE DATABASE &&QA_PDB CLOSE IMMEDIATE INSTANCES = ALL;
PROMPT     DROP PLUGGABLE DATABASE &&QA_PDB INCLUDING DATAFILES;

DECLARE
    l_count      NUMBER;
    l_open_count NUMBER;
BEGIN
    SELECT COUNT(*)
    INTO   l_count
    FROM   dba_pdbs
    WHERE  pdb_name = UPPER('&&QA_PDB');

    IF l_count = 0 THEN
        dbms_output.put_line('Skipping &&QA_PDB: not found');
    ELSE
        SELECT COUNT(*)
        INTO   l_open_count
        FROM   gv$pdbs
        WHERE  name = UPPER('&&QA_PDB')
        AND    open_mode <> 'MOUNTED';

        IF l_open_count > 0 THEN
            EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&QA_PDB CLOSE IMMEDIATE INSTANCES = ALL';
        END IF;

        EXECUTE IMMEDIATE 'DROP PLUGGABLE DATABASE &&QA_PDB INCLUDING DATAFILES';
    END IF;
END;
/

DEFINE LAB_PAUSE_MESSAGE = "Press Return to create &&QA_PDB from &&LATEST_CAROUSEL_SNAPSHOT."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   CREATE PLUGGABLE DATABASE &&QA_PDB
PROMPT     FROM &&MAIN_PDB
PROMPT     USING SNAPSHOT &&LATEST_CAROUSEL_SNAPSHOT
PROMPT     SNAPSHOT COPY;

CREATE PLUGGABLE DATABASE &&QA_PDB
    FROM &&MAIN_PDB
    USING SNAPSHOT &&LATEST_CAROUSEL_SNAPSHOT
    SNAPSHOT COPY;

DEFINE LAB_PAUSE_MESSAGE = "Press Return to open &&QA_PDB across all RAC instances."
@@../common/&&LAB_PAUSE_SCRIPT

PROMPT SQL/DDL:
PROMPT   ALTER PLUGGABLE DATABASE &&QA_PDB OPEN READ WRITE INSTANCES = ALL;

DECLARE
    l_attempts CONSTANT PLS_INTEGER := 30;
BEGIN
    FOR i IN 1 .. l_attempts LOOP
        BEGIN
            EXECUTE IMMEDIATE 'ALTER PLUGGABLE DATABASE &&QA_PDB OPEN READ WRITE INSTANCES = ALL';
            dbms_output.put_line('Opened &&QA_PDB across all RAC instances.');
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

DEFINE LAB_PAUSE_MESSAGE = "Press Return to verify &&QA_PDB and snapshot carousel state."
@@../common/&&LAB_PAUSE_SCRIPT

@@../common/verify-pdbs.sql
@@../common/verify-pdb-services.sql
@@../common/verify-snapshots.sql
@@../common/verify-storage.sql

PROMPT QA clone created from the latest available snapshot
