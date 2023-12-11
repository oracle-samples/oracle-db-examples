drop table products;
create table products(name varchar2(60), vendor varchar2(60), rating number, price number, mydate date);

insert all
 into products values ('cherry red shoes', 'Sports USA', 5, 129, sysdate)
 into products values ('bright red shoes', 'Sports USA', 4, 109, sysdate)
 into products values ('more red shoes', 'Shoeware', 5, 129, sysdate)
 into products values ('shoes', 'Runners inc', 5, 109, sysdate)
select * from dual;

-- The following statements create a MULTI_COLUMN_DATASTORE preference named ds 
-- to bring various other columns into the index (name) to be used as facets:
-- multi col datastore automatically adds tags by default so the text to be indexed looks like
-- '<name>cherry red shoes</name><vendor>Sports USA</vendor><rating> .... '

exec ctx_ddl.drop_preference  ('ds');
exec ctx_ddl.create_preference('ds', 'MULTI_COLUMN_DATASTORE')
exec ctx_ddl.set_attribute    ('ds', 'COLUMNS', 'name, vendor, rating, price, mydate')

-- A Section Group is created to specify the data type of each column (varchar2 is the default) 
-- and how each column that is brought into the index should be used.

exec ctx_ddl.drop_section_group   ('sg')
exec ctx_ddl.create_section_group ('sg', 'BASIC_SECTION_GROUP')

exec ctx_ddl.add_sdata_section    ('sg', 'vendor', 'vendor', 'VARCHAR2')
exec ctx_ddl.add_sdata_section    ('sg', 'rating', 'rating', 'NUMBER')
exec ctx_ddl.add_sdata_section    ('sg', 'price',  'price', 'NUMBER')
exec ctx_ddl.add_sdata_section    ('sg', 'mydate', 'mydate', 'DATE')

exec ctx_ddl.set_section_attribute('sg', 'vendor', 'optimized_for', 'SEARCH')
exec ctx_ddl.set_section_attribute('sg', 'rating', 'optimized_for', 'SEARCH')
exec ctx_ddl.set_section_attribute('sg', 'price',  'optimized_for', 'SEARCH')
exec ctx_ddl.set_section_attribute('sg', 'mydate', 'optimized_for', 'SEARCH')

-- The following statement creates an index on name and specifies the preferences by using the parameters clause:

CREATE INDEX product_index ON products (name)
INDEXTYPE IS ctxsys.context
PARAMETERS ('datastore ds section group sg');

-- The following statements query for a product name, ‘red shoes’ and the facets for computation can be specified. 
-- The count attribute is used to show the total number of items that match the query for the product. 
-- The result set interface is used to specify various requirements such as, showing the top vendors that have 
-- the largest number of items that match, lowest prices available, and latest arrivals:

set serveroutput on size 500000

set long 500000
set pagesize 0

variable displayrs clob;

declare
  rs clob;
begin
   ctx_query.result_set('product_index', 'red shoes', '<ctx_result_set_descriptor>
	 <count/>
	 <group sdata="vendor" topn="5" sortby="count" order="desc">
	 <count exact="true"/>
	 </group>
	 <group sdata="price" topn="3" sortby="value" order="asc">
	 <count exact="true"/>
	 </group>
	 <group sdata="mydate" topn="3" sortby="value" order="desc">
	 <count exact="true"/>
	 </group>
	 </ctx_result_set_descriptor>',
	 rs);
   -- pretty-print the result set (rs) for display purposes. No need if we're going to 
   -- manipulate it in XML
   select xmlserialize(Document XMLType(rs) as clob indent size=2) into :displayrs from dual;
   dbms_lob.freetemporary(rs);
end;
/
select :displayrs from dual;

