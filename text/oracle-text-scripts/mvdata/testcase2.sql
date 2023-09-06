set long 50000
set pagesize 255

variable rsout clob
variable res   clob
variable rsd   clob

DROP TABLE products;

CREATE TABLE products( 
  model      VARCHAR2(249),  -- max length for SDATA col
  price      NUMBER,
  stock      NUMBER,
  rel_date   DATE,
  facetlist  VARCHAR2(255)
);

-- Here is the data for indexing.

INSERT INTO products VALUES( 'Nikon C400',             129, 10, '22-JUN-2012', '1,5,9'  );
INSERT INTO products VALUES( 'Nikon C401 (Nikon USA)', 149, 5,  '29-JUN-2012', '1,5,9'  );
INSERT INTO products VALUES( 'Nikon B40',              190, 2,  '30-JUN-2012', '1,6,10' );
INSERT INTO products VALUES( 'Nikon SLRX',             445, 0,  '02-JUL-2012', '4,8,11' );

EXECUTE ctx_ddl.drop_preference     ( 'mc_ds' )
EXECUTE ctx_ddl.create_preference   ( 'mc_ds', 'MULTI_COLUMN_DATASTORE')
EXECUTE ctx_ddl.set_attribute       ( 'mc_ds', 'COLUMNS', 'model, facetlist')

EXECUTE ctx_ddl.drop_section_group  ( 'sec_grp' )
EXECUTE ctx_ddl.create_section_group( 'sec_grp', 'BASIC_SECTION_GROUP' )
	
EXECUTE ctx_ddl.add_mvdata_section  ( 'sec_grp', 'facetlist', 'facetlist' )
EXECUTE ctx_ddl.add_mvdata_section  ( 'sec_grp', 'datefacets', 'datefacets' );

EXECUTE ctx_ddl.drop_preference     ( 'storage' )
EXECUTE ctx_ddl.create_preference   ( 'storage', 'BASIC_STORAGE' )
EXECUTE ctx_ddl.set_attribute       ( 'storage', 'BIG_IO',    'TRUE' )

CREATE INDEX productsindex ON products(model )INDEXTYPE IS ctxsys.context
FILTER BY model, price
PARAMETERS( 'datastore mc_ds section group sec_grp storage storage' );

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

exec ctx_query.result_set( 'productsindex', 'nikon', :rsd, :rsout)

