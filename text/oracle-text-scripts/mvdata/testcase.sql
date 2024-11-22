variable rsd   clob
variable rsout clob

DROP TABLE products;

CREATE TABLE products( 
  text       varchar2(1),
  model      varchar2(120),
  facetlist  varchar2(255),
  price      number
);

-- Here is the data for indexing.

set feedback off
INSERT INTO products values( 'x', 'Nikon C400',             '1,5,9',  129 );
INSERT INTO products values( 'x', 'Nikon C401 (Nikon USA)', '1,5,9',  149 );
INSERT INTO products values( 'x', 'Nikon B40',              '1,6,10', 190 );
INSERT INTO products values( 'x', 'Nikon SLRX',             '4,8,11', 445 );

EXECUTE ctx_ddl.drop_preference     ( 'ds' );
EXECUTE ctx_ddl.create_preference   ( 'ds', 'multi_column_datastore' )
EXECUTE ctx_ddl.set_attribute       ( 'ds', 'columns', 'model as text, facetlist' )

set feedback on

EXECUTE ctx_ddl.drop_section_group  ( 'sec_grp' )
EXECUTE ctx_ddl.create_section_group( 'sec_grp', 'BASIC_SECTION_GROUP' )
	
EXECUTE ctx_ddl.add_mvdata_section  ( 'sec_grp', 'facetlist', 'facetlist' )
EXECUTE ctx_ddl.add_sdata_column    ( 'sec_grp', 'model', 'model' )
-- EXECUTE ctx_ddl.add_sdata_section   ( 'sec_grp', 'model', 'model' )

EXECUTE ctx_ddl.drop_preference     ( 'storage' )
EXECUTE ctx_ddl.create_preference   ( 'storage', 'BASIC_STORAGE' )
EXECUTE ctx_ddl.set_attribute       ( 'storage', 'BIG_IO',    'TRUE' )

CREATE INDEX productsindex ON products(text )INDEXTYPE IS ctxsys.context
FILTER BY model
PARAMETERS( 'datastore ds section group sec_grp storage storage' );

-- check that the sdata section works
select * from products where contains (text, 'nikon and sdata(model="Nikon C400")' ) > 0;

-- now RSI

begin
  :rsd := '
<ctx_result_set_descriptor>
  <count />
  <hitlist start_hit_num="1" end_hit_num="5" order="score desc">
    <score />
    <rowid />
    <sdata name="model"/>
  </hitlist>
  <group mvdata = "facetlist">
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

delete from res_output;
insert into res_output values (xmltype(:rsout));

set long 50000
select * from res_output;
