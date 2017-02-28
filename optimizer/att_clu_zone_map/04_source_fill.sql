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

PROMPT Connect to the Attribute Clusters/Zone Map Schema
connect aczm12c/oracle_4U

--
PROMPT Drop and create a sequence
--

DROP sequence nseq
/
CREATE sequence nseq CACHE 10000
/

--
PROMPT Utility procedure to fill SALES_SOURCE table
--

CREATE OR REPLACE
PROCEDURE filltab(
    p_start_date DATE,
    p_number_of_rows NUMBER,
    p_number_of_days NUMBER)
AS
TYPE sa_tab_type
IS
  TABLE OF sales_source.sale_agent%TYPE INDEX BY BINARY_INTEGER;
  sa_tab sa_tab_type;
TYPE wh_type
IS
  TABLE OF sales_source.warehouse%TYPE INDEX BY BINARY_INTEGER;
  wh_tab          wh_type;
  sale_date       DATE;
  num_order_items NUMBER(2);
  sa              sales_source.sale_agent%TYPE;
  product         sales_source.product_id%TYPE;
  location        sales_source.location_id%TYPE;
  wh              sales_source.warehouse%TYPE;
  order_id        sales_source.order_id%TYPE;
  num_products    NUMBER(5);
  num_locations   NUMBER(5);
  max_order_items NUMBER(3)  := 20;
  num_inserted    NUMBER(10) := 0;
  loop_count      NUMBER(10) := 0;
  counter         NUMBER(10);
  deliv_days      NUMBER(3);
BEGIN
  sa_tab(1)  := 'MARK';
  sa_tab(2)  := 'CLARE';
  sa_tab(3)  := 'ANDREW';
  sa_tab(4)  := 'LUCY';
  sa_tab(5)  := 'JENNY';
  sa_tab(6)  := 'JOHN';
  sa_tab(7)  := 'BRIAN';
  sa_tab(8)  := 'JANE';
  sa_tab(9)  := 'ED';
  sa_tab(10) := 'SIMON';
  sa_tab(11) := 'SALLY';
  wh_tab(1)  := 'ALBUQUERQUE';
  wh_tab(2)  := 'WINSTON SALEM';
  wh_tab(3)  := 'NEWPORT';
  wh_tab(4)  := 'BIRMINGHAM';
  wh_tab(5)  := 'OCOEE';
  wh_tab(6)  := 'PRINCETON';
  order_id   := nseq.nextval;
  sale_date  := p_start_date;
  SELECT COUNT(*) INTO num_products FROM products;
  SELECT COUNT(*) INTO num_locations FROM locations;
  LOOP
    num_order_items:= dbms_random.value(1,max_order_items+1);
    order_id       := nseq.nextval;
    sale_date      := p_start_date + dbms_random.value(0,floor(p_number_of_days+1));
    wh             := wh_tab(floor(dbms_random.value(1,7)));
    sa             := sa_tab(floor(dbms_random.value(1,12)));
    deliv_days     := dbms_random.value(2,30);    
    INSERT INTO sales_source
    SELECT order_id ,
      rownum ,
      sale_date ,
      sale_date + deliv_days ,
      sa ,
      dbms_random.value(1,floor(num_products)) ,
      dbms_random.value(1,2000) ,
      dbms_random.value(1,3) ,
      dbms_random.value(1,floor(num_locations)) ,
      wh
    FROM dual
      CONNECT BY rownum    <= num_order_items;
    num_inserted           := num_inserted + num_order_items;
    loop_count             := loop_count   + 1;
    IF mod(loop_count,1000) = 0 THEN
      COMMIT;
    END IF;
    EXIT WHEN num_inserted >= p_number_of_rows;
  END LOOP;
  COMMIT;
END;
/
show errors

--
PROMPT Fill the SALES_SOURCE table with data for 2000 and 2009
PROMPT This may take several minutes...
--

EXECUTE filltab(to_date('01-JAN-2000','DD-MON-YYYY'),1452090,364);
EXECUTE filltab(to_date('01-JAN-2009','DD-MON-YYYY'),500000,364);

--
PROMPT Gather table statistics...
--
EXECUTE dbms_stats.gather_table_stats(ownname=>NULL,tabname=>'sales_source');

