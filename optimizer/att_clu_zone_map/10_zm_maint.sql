-- DISCLAIMER:
-- This script is provided for educational purposes only. It is 
-- NOT supported by Oracle World Wide Technical Support.
-- The script has been tested and appears to work as intended.
-- You should always run new scripts initially 
-- on a test instance.

set timing off
set echo off
set lines 400 pages 1000
set feedback 1
set pause off
set echo on
set autotrace off
column plan_table_output format a150
set trims on

PROMPT Connect to the Attribute Clusters/Zone Map Schema
connect aczm12c/oracle_4U

--
PROMPT Delete operations do not invalidate zones or partitions
PROMPT because they will not invalidate MIN/MAX value ranges.

--
DELETE FROM sales_p WHERE order_id = 10
/
COMMIT
/

PROMPT Observe that the state remains "0" for all zones and partitions

SELECT zone_id$ ,
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

PROMPT The zone map is not made stale...

SELECT stale 
FROM   user_zonemaps
WHERE  zonemap_name = 'ZMAP$_SALES_P'
/

--
PROMPT Conventional path insert will invalidate
PROMPT relevant zones and partitions unless
PROMPT the zone map is set to refresh on commit.
--
INSERT INTO sales_p
SELECT 10,1,TO_DATE('01-JAN-2000','DD-MON-YYYY'),TO_DATE('02-JAN-2000','DD-MON-YYYY'),'JANE',23,20,2,67,'WINSTON SALEM'
FROM   dual
/
COMMIT
/

PROMPT Individual zones are now invalidated...

SELECT zone_id$ ,
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

PROMPT But the zone map is not stale...

SELECT stale 
FROM   user_zonemaps
WHERE  zonemap_name = 'ZMAP$_SALES_P'
/

PROMPT If the zone map itself is not stale,
PROMPT a fast refresh is possible.
PROMPT Only stale zones are scanned to refresh
PROMPT the zone map.

EXECUTE dbms_mview.refresh('ZMAP$_SALES_P', 'f');

PROMPT The zones are valid (0) again...

SELECT zone_id$ ,
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

PROMPT Remove the "test" row. Zones will remain valid.

DELETE FROM sales_p WHERE order_id = 10
/
COMMIT
/

PROMPT Direct path operations will maintain the zone map

INSERT /*+ APPEND */ INTO sales_p
SELECT 10,1,TO_DATE('01-JAN-2000','DD-MON-YYYY'),TO_DATE('02-JAN-2000','DD-MON-YYYY'),'JANE',23,20,2,67,'WINSTON SALEM'
FROM   dual
/
COMMIT
/

PROMPT All zones still valid...

SELECT zone_id$ ,
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

--
PROMPT Updates to non-zone map columns (and columns not 
PROMPT used to join with dimension tables)
PROMPT do not invalidate the zones or partitions
PROMPT (unless there is row movement when a 
PROMPT  partition key is updated)
--
UPDATE sales_p SET amount = amount + 100
WHERE location_id < 20
/
COMMIT
/

PROMPT All zones are still valid...

SELECT zone_id$ ,
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

PROMPT Remove the "test" row. Zones will remain valid.

DELETE FROM sales_p WHERE order_id = 10
/
COMMIT
/

PROMPT A conventional path insert will invalidate zones...

INSERT INTO sales_p
SELECT 10,1,TO_DATE('01-JAN-2000','DD-MON-YYYY'),TO_DATE('02-JAN-2000','DD-MON-YYYY'),'JANE',23,20,2,67,'WINSTON SALEM'
FROM   dual
/
COMMIT
/

PROMPT Note invalid zones (marked with "1")...

SELECT zone_id$ ,
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

PROMPT Even if some zones are stale, 
PROMPT queries will continue to use the zone map where possible.
PROMPT The primary effect of zones being markes as stale
PROMPT is that these zones cannot be skipped: stale zones 
PROMPT and partitions will always be scanned.

SELECT SUM(amount)
FROM   sales_p
WHERE  delivered  between TO_DATE('18-SEP-2000', 'DD-MON-YY') and TO_DATE('19-SEP-2000', 'DD-MON-YY')
/

SELECT * FROM TABLE(dbms_xplan.display_cursor);

PROMPT Data movement can maintain zone maps
PROMPT and attribute clusters.

ALTER TABLE sales_p MOVE PARTITION p1
/

PROMPT All zones are valid (0)...

SELECT zone_id$ ,
  zone_level$,
  zone_state$ ,
  zone_rows$
FROM ZMAP$_SALES_P;

PROMPT Remove the "test" row. Zones will remain valid.

DELETE FROM sales_p WHERE order_id = 10
/
COMMIT
/
