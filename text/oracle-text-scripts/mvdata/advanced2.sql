set long 50000
set pagesize 255

DROP TABLE res_output;
CREATE TABLE res_output( res xmltype );

DROP TABLE facettable;

CREATE TABLE facettable( 
   facet_id            NUMBER,          -- this will be the number used in MVDATA
   facet_name          VARCHAR2(40),    -- facet name, or category
   facet_value         VARCHAR2(20),    -- facet value, or a division within a category
   facet_group         NUMBER,          -- defines the display order for categories
   facet_display_order NUMBER           -- order to display facets (new for this example)
);

-- Now load the facet tracking information.

INSERT INTO facettable values( 1,  'Resolution',  '10MP',    1, 1 );
INSERT INTO facettable values( 2,  'Resolution',  '12MP',    1, 2 );
INSERT INTO facettable values( 3,  'Resolution',  '15MP',    1, 3 );
INSERT INTO facettable values( 4,  'Resolution',  '> 15MP',  1, 4 );

INSERT INTO facettable values( 5,  'Price',       '100-150', 2, 1 );
INSERT INTO facettable values( 6,  'Price',       '150-200', 2, 2 );
INSERT INTO facettable values( 7,  'Price',       '200-250', 2, 3 );
INSERT INTO facettable values( 8,  'Price',       '> 250',   2, 4  );

INSERT INTO facettable values( 9,  'Body Type',   'Compact', 3, 1 );
INSERT INTO facettable values( 10, 'Body Type',   'Bridge',  3, 2 );
INSERT INTO facettable values( 11, 'Body Type',   'SLR',     3, 3 );

INSERT INTO facettable values( 12, 'Stock Level', '0',       4, 7 ); 
INSERT INTO facettable values( 13, 'Stock Level', '1',       4, 6 ); 
INSERT INTO facettable values( 14, 'Stock Level', '2',       4, 5 ); 
INSERT INTO facettable values( 15, 'Stock Level', '3',       4, 4 ); 
INSERT INTO facettable values( 16, 'Stock Level', '4',       4, 3 ); 
INSERT INTO facettable values( 17, 'Stock Level', '5',       4, 2 ); 
INSERT INTO facettable values( 18, 'Stock Level', '> 5',     4, 1 );

INSERT INTO facettable values( 19, 'Release Date', 'Today',     5, 1 );
INSERT INTO facettable values( 20, 'Release Date', 'This week' ,5, 2 );
INSERT INTO facettable values( 21, 'Release Date', 'Last week' ,5, 2 );
INSERT INTO facettable values( 22, 'Release Date', 'Older'     ,5, 2 );

DROP TABLE products;

CREATE TABLE products( 
  model      VARCHAR2(249),  -- max length for SDATA col
  price      NUMBER,
  stock      NUMBER,
  rel_date   DATE,
  facetlist  VARCHAR2(255)
);

-- Here is the data for indexing.

INSERT INTO products VALUES( 'Nikon C400',             129, 10, SYSDATE-10, '1,5,9'  );
INSERT INTO products VALUES( 'Nikon C401 (Nikon USA)', 149, 5,  SYSDATE-8,  '1,5,9'  );
INSERT INTO products VALUES( 'Nikon B40',              190, 2,  SYSDATE-3,  '1,6,10' );
INSERT INTO products VALUES( 'Nikon SLRX',             445, 0,  SYSDATE,    '4,8,11' );

EXECUTE ctx_ddl.drop_preference     ( 'mc_ds' )
EXECUTE ctx_ddl.create_preference   ( 'mc_ds', 'MULTI_COLUMN_DATASTORE')
EXECUTE ctx_ddl.set_attribute       ( 'mc_ds', 'COLUMNS', 'model, facetlist')

EXECUTE ctx_ddl.drop_section_group  ( 'sec_grp' )
EXECUTE ctx_ddl.create_section_group( 'sec_grp', 'BASIC_SECTION_GROUP' )
	
EXECUTE ctx_ddl.add_mvdata_section  ( 'sec_grp', 'facetlist',   'facetlist'   )
EXECUTE ctx_ddl.add_mvdata_section  ( 'sec_grp', 'stockfacets', 'stockfacets' );
EXECUTE ctx_ddl.add_mvdata_section  ( 'sec_grp', 'datefacets',  'datefacets'  );

EXECUTE ctx_ddl.drop_preference     ( 'storage' )
EXECUTE ctx_ddl.create_preference   ( 'storage', 'BASIC_STORAGE' )
EXECUTE ctx_ddl.set_attribute       ( 'storage', 'BIG_IO',    'TRUE' )

CREATE INDEX productsindex ON products(model )INDEXTYPE IS ctxsys.context
FILTER BY model, price
PARAMETERS( 'datastore mc_ds section group sec_grp storage storage' );

-- Initialize the stock level facet for all items

CREATE OR REPLACE procedure set_stock_levels IS
  rowids         SYS.odciRidList;
  facets         SYS.odciNumberList;
  stock_facet    INTEGER;
BEGIN
  -- initialize collections
  rowids := SYS.odciRidList();
  facets := SYS.odciNumberList();

  FOR c IN ( SELECT rowid, stock FROM products ) LOOP
    CASE c.stock
      WHEN 0 THEN stock_facet := 12; 
      WHEN 1 THEN stock_facet := 13; 
      WHEN 2 THEN stock_facet := 14; 
      WHEN 3 THEN stock_facet := 15; 
      WHEN 4 THEN stock_facet := 16; 
      WHEN 5 THEN stock_facet := 17; 
      ELSE        stock_facet := 18;
    END CASE;

    facets.EXTEND(1);
    facets(facets.LAST) := stock_facet;

    rowids.EXTEND(1);
    rowids(rowids.LAST) := c.rowid;

    ctx_ddl.insert_mvdata_values (
      idx_name       => 'productsindex', 
      section_name   => 'stockfacets', 
      mvdata_values  => facets, 
      mvdata_rowids  => rowids );

    rowids.DELETE;
    facets.DELETE;

  END LOOP;    
END set_stock_levels;
/
list
show errors

EXECUTE set_stock_levels;

-- Now create the trigger which will keep the stock facet up to date with 
-- the stock level in the products table

CREATE OR REPLACE TRIGGER stock_facet_trigger
AFTER UPDATE ON products
FOR EACH ROW
DECLARE 
  rowids         SYS.odciRidList;
  facets         SYS.odciNumberList;
  stock_facet    INTEGER;
BEGIN
  -- initialize collections
  rowids := SYS.odciRidList(1);
  facets := SYS.odciNumberList(1);

  CASE :OLD.stock
    WHEN 0 THEN stock_facet := 12; 
    WHEN 1 THEN stock_facet := 13; 
    WHEN 2 THEN stock_facet := 14; 
    WHEN 3 THEN stock_facet := 15; 
    WHEN 4 THEN stock_facet := 16; 
    WHEN 5 THEN stock_facet := 17; 
    ELSE        stock_facet := 18;
  END CASE;

  rowids(1) := :OLD.rowid;
  facets(1) := stock_facet;

  ctx_ddl.delete_mvdata_values (
      idx_name       => 'productsindex', 
      section_name   => 'stockfacets', 
      mvdata_values  => facets, 
      mvdata_rowids  => rowids );

  CASE :NEW.stock
    WHEN 0 THEN stock_facet := 12; 
    WHEN 1 THEN stock_facet := 13; 
    WHEN 2 THEN stock_facet := 14; 
    WHEN 3 THEN stock_facet := 15; 
    WHEN 4 THEN stock_facet := 16; 
    WHEN 5 THEN stock_facet := 17; 
    ELSE        stock_facet := 18;
  END CASE;

  rowids(1) := :NEW.rowid;
  facets(1) := stock_facet;

  ctx_ddl.insert_mvdata_values (
      idx_name       => 'productsindex', 
      section_name   => 'stockfacets', 
      mvdata_values  => facets, 
      mvdata_rowids  => rowids );

END stock_facet_trigger;
/
list
show errors

-- Now run a query and collect stock level facets:

variable rsout clob
variable res   clob
variable rsd   clob

begin
  :rsd := '
<ctx_result_set_descriptor>
  <count />
  <hitlist start_hit_num="1" end_hit_num="5" order="score desc">
    <score />
    <rowid />
    <sdata name="model"/>
    <sdata name="price"/>
  </hitlist>
  <group mvdata="stockfacets">
    <group_values>
      <value id = "12" />
      <value id = "13" />
      <value id = "14" />
      <value id = "15" />
      <value id = "16" />
      <value id = "17" />
      <value id = "18" />
    </group_values>
    <count/>
  </group>
</ctx_result_set_descriptor>
';
END;
/

BEGIN
  dbms_lob.createtemporary(:rsout, true);
  ctx_query.result_set( 'productsindex', 'nikon', :rsd, :rsout);
  DELETE FROM res_output;
  INSERT INTO res_output VALUES ( xmlType(:rsout) );
END;
/

SELECT res FROM res_output;     --

-- Now get the facets and counts:

SELECT ft.facet_name, ft.facet_value, rs.facet_count
 FROM facettable ft, res_output r, XMLTABLE 
('/ctx_result_set/groups/group'
PASSING r.res
  COLUMNS 
    facet_id     NUMBER PATH '@value',
    facet_count  NUMBER PATH 'count/text()'
) as rs 
where     rs.facet_id = ft.facet_id
and       rs.facet_count > 0
order by  facet_display_order;

-- Increase the stock level for Nikon B40 to 5:

UPDATE products SET stock = 5 WHERE model = 'Nikon B40';

BEGIN
  dbms_lob.createtemporary(:rsout, true);
  ctx_query.result_set( 'productsindex', 'nikon', :rsd, :rsout);
  DELETE FROM res_output;
  INSERT INTO res_output VALUES ( xmlType(:rsout) );
END;
/

SELECT res FROM res_output;     --

-- Now get the facets and counts:

SELECT ft.facet_name, ft.facet_value, rs.facet_count
 FROM facettable ft, res_output r, XMLTABLE 
('/ctx_result_set/groups/group'
PASSING r.res
  COLUMNS 
    facet_id     NUMBER PATH '@value',
    facet_count  NUMBER PATH 'count/text()'
) as rs 
where     rs.facet_id = ft.facet_id
and       rs.facet_count > 0
order by  facet_display_order;

