set long 50000
set pagesize 255

variable rsout clob
variable res   clob
variable rsd   clob

DROP TABLE res_output;
CREATE TABLE res_output( res clob );

DROP TABLE test;
CREATE TABLE test(text VARCHAR2(4000));

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

INSERT INTO facettable values( 12, 'Stock Level', '0',       4, 1 ); 
INSERT INTO facettable values( 13, 'Stock Level', '1',       4, 1 ); 
INSERT INTO facettable values( 14, 'Stock Level', '2',       4, 2 ); 
INSERT INTO facettable values( 15, 'Stock Level', '3',       4, 3 ); 
INSERT INTO facettable values( 16, 'Stock Level', '4',       4, 4 ); 
INSERT INTO facettable values( 17, 'Stock Level', '5',       4, 5 ); 
INSERT INTO facettable values( 18, 'Stock Level', '> 5',     4, 6 );

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

create or replace procedure update_date_facets (
  date_label varchar2,
  min_age    integer,
  max_age    integer
) is 
  rowids sys.odciRidList;
  facets sys.odciNumberList;
  num    integer;
BEGIN
  -- initialize collections
  rowids := sys.odciRidList();
  facets := sys.odciNumberList();

  -- Fetch the relevant facet id for the label (facet value, eg "Today")
  select facet_id into num from facettable 
    where facet_name = 'Release Date' and facet_value = date_label;
  facets.extend(1);
  facets(facets.last) := num;

  -- Now get all the rowids which match the specified date range
  for c in ( select rowid from products 
             where trunc(SYSDATE) - trunc(rel_date) between min_age and max_age ) loop
    rowids.extend(1);
    rowids(rowids.last) := c.rowid;
  end loop;

  if rowids.count > 0 then
    -- insert the MVDATA value
    -- need to explicitly GRANT EXECUTE ON CTXSYS.CTXDDL to this user
    ctx_ddl.insert_mvdata_values (
      idx_name       => 'productsindex', 
      section_name   => 'datefacets', 
      mvdata_values  => facets, 
      mvdata_rowids  => rowids );

    dbms_output.put_line('updating '||rowids.count||' rowids for facet '||num);
  end if;

END update_date_facets;
/
-- list
show errors

--exec update_date_facets('Today',     0, 0);
--exec update_date_facets('This week', 1, 6);
--exec update_date_facets('Last week', 7, 13);

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
  <group mvdata="facetlist">
    <group_values>
      <value id = "1"/>
      <value id = "2"/>
      <value id = "3"/>
      <value id = "4"/>
      <value id = "5"/>
      <value id = "6"/>
      <value id = "7"/>
      <value id = "8"/>
      <value id = "9"/>
      <value id = "10"/>
      <value id = "11"/>
    </group_values>
    <count/>
  </group>
</ctx_result_set_descriptor>
';
  dbms_lob.createtemporary(:rsout, true);
end;
/

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
`>  <group mvdata="datefacets" topn="10">
    <count/>
  </group>
</ctx_result_set_descriptor>
';
  dbms_lob.createtemporary(:rsout, true);
end;
/

exec ctx_query.result_set( 'productsindex', 'nikon', :rsd, :rsout)

select xmltype(:rsout) from dual;

insert into res_output values (xmltype(:rsout));

break on FACET_NAME skip 1

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
order by  ft.facet_group, rs.facet_count desc;

-- Initialize the stock level facet for all items

CREATE OR REPLACE procedure set_stock_levels IS
  rowids         sys.odciRidList;
  facets         sys.odciNumberList;
  stock_facet    INTEGER;
BEGIN
  -- initialize collections
  rowids := sys.odciRidList();
  facets := sys.odciNumberList();

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

-- exec set_stock_levels;

declare
  rsd   clob;
  rsout clob;
begin
  rsd := '
<ctx_result_set_descriptor>
  <count />
  <hitlist start_hit_num="1" end_hit_num="5" order="score desc">
    <score />
    <rowid />
    <sdata name="model"/>
    <sdata name="price"/>
  </hitlist>
  <group mvdata="stockfacets" topn="10">
    <count/>
  </group>
</ctx_result_set_descriptor>
';
  dbms_lob.createtemporary(rsout, true);
  ctx_query.result_set( 'productsindex', 'nikon', rsd, rsout);
  delete from res_output;
  insert into res_output values (rsout);
  insert into test values (rsout);
end;
/

set echo on

select res from res_output;

select xmltype(res) from res_output;

select dump(text) from test;
