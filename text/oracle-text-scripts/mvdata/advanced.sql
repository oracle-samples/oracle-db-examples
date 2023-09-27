set long 50000
set pagesize 255

variable rsout clob
variable res   clob
variable rsd   clob

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

CREATE OR REPLACE PROCEDURE update_date_facets (
  date_label VARCHAR2,
  min_age    INTEGER,
  max_age    INTEGER
) IS 
  rowids SYS.odciRidList;
  facets SYS.odciNumberList;
  num    INTEGER;
BEGIN
  -- initialize collections
  rowids := SYS.odciRidList();
  facets := SYS.odciNumberList();

  -- Fetch the relevant facet id for the label (facet value, eg "Today")
  SELECT facet_id INTO num FROM facettable 
    WHERE facet_name = 'Release Date' AND facet_value = date_label;
  facets.EXTEND(1);
  facets(facets.LAST) := num;

  -- Now get all the rowids which match the specified date range
  FOR c IN ( SELECT rowid FROM products 
             where TRUNC(SYSDATE) - TRUNC(rel_date) BETWEEN min_age AND max_age ) loop
    rowids.EXTEND(1);
    rowids(rowids.LAST) := c.ROWID;
  END LOOP;

  IF rowids.COUNT > 0 THEN
    -- update the MVDATA values
    -- need to explicitly GRANT EXECUTE ON CTXSYS.CTXDDL to this user
    ctx_ddl.update_mvdata_set (
      idx_name       => 'productsindex', 
      section_name   => 'datefacets', 
      mvdata_values  => facets, 
      mvdata_rowids  => rowids );
  END IF;

END update_date_facets;
/
-- list
show errors

EXECUTE update_date_facets('Today',     0, 0)
EXECUTE update_date_facets('This week', 1, 6)
EXECUTE update_date_facets('Last week', 7, 13)
EXECUTE update_date_facets('Older',    14, 9999)
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
  <group mvdata="datefacets" topn="10">
    <count/>
  </group>
</ctx_result_set_descriptor>
';
  dbms_lob.createtemporary(:rsout, true);
end;
/

EXECUTE ctx_query.result_set( 'productsindex', 'nikon', :rsd, :rsout)

select xmltype(:rsout) from dual;

insert into res_output values (xmltype(:rsout));

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
