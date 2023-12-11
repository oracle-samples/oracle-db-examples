
-- SQL*Plus script to demonstrate the use of MVDATA to do faceted navigation
-- user running this script needs to have CTXAPP role

-- This demo assumes a storefront web app selling cameras. The faceted navigation
-- has various categories:
--    Resolution
--    Price
--    Body Type
-- and each category is divided into various groups, eg for resolution we have
-- megapixel counts:
--      10MP
--      12MP
--      15MP
--      > 15 MP

-- Each group within each category is assigned a FACET VALUE. These are just
-- numbers, Oracle Text does not know or care what any particular number 
-- represents. It is up to the application to keep track of what the numbers
-- mean in the real world.

-- first do some display housekeeping

set long 50000
set pagesize 25

-- drop the tables we're going to use (will cause errors on first invocation)

DROP TABLE products;
DROP TABLE facettable;
DROP TABLE res_output;

-- this is our main data table

CREATE TABLE products( text varchar2(2000) );

-- Here is the data for indexing. Note that we've chosen to load the
-- facet values in a field - instead we might have decided to use 
-- ctx_ddl.insert_mvdata_values after the main rows were inserted.

INSERT INTO products values( 'Nikon C400 <facetlist>1,5,9</facetlist>' );
INSERT INTO products values( 'Nikon C401 <facetlist>1,5,9</facetlist>' );
INSERT INTO products values( 'Nikon B40 <facetlist>1,6,10</facetlist>' );
INSERT INTO products values( 'Nikon SLRX <facetlist>4,8,11</facetlist>' );

-- this is our facet table. This keeps track of what facets "mean" to our
-- application. Oracle Text only knows about numbers, PRICE > 250 might be
-- represented by a number "20". Oracle Text doesn't know about this table,
-- and doesn't care what "20" means: it's up to our application to control 
-- the meaning

CREATE TABLE facettable( 
   facet_id            NUMBER,          -- this will be the number used in MVDATA
   facet_name          VARCHAR2(40),    -- facet name, or category
   facet_value         VARCHAR2(20),    -- facet value, or a division within a category
   facet_group         NUMBER,          -- defines the display order for categories
   facet_display_order NUMBER           -- not used in this example as we always order
                                        --   by the count within a category
);

-- Now load the facet tracking information.

INSERT INTO facettable values( 1,  'Resolution', '10MP',    1, 1 );
INSERT INTO facettable values( 2,  'Resolution', '12MP',    1, 2 );
INSERT INTO facettable values( 3,  'Resolution', '15MP',    1, 3 );
INSERT INTO facettable values( 4,  'Resolution', '> 15MP',  1, 4 );

INSERT INTO facettable values( 5,  'Price',      '100-150', 2, 1 );
INSERT INTO facettable values( 6,  'Price',      '150-200', 2, 2 );
INSERT INTO facettable values( 7,  'Price',      '200-250', 2, 3 );
INSERT INTO facettable values( 8,  'Price',      '> 250',   2, 4  );

INSERT INTO facettable values( 9,  'Body Type',  'Compact', 3, 1 );
INSERT INTO facettable values( 10, 'Body Type',  'Bridge',  3, 2 );
INSERT INTO facettable values( 11, 'Body Type',  'SLR',     3, 3 );

-- this is a table used for query output

CREATE TABLE res_output( res xmltype );

-- Oracle Text index setup

EXECUTE ctx_ddl.drop_section_group  ( 'sec_grp' )
EXECUTE ctx_ddl.create_section_group( 'sec_grp', 'BASIC_SECTION_GROUP' )

EXECUTE ctx_ddl.add_mvdata_section  ( 'sec_grp', 'facetlist', 'facetlist' )

EXECUTE ctx_ddl.drop_preference     ( 'storage' )
EXECUTE ctx_ddl.create_preference   ( 'storage', 'BASIC_STORAGE' )

EXECUTE ctx_ddl.set_attribute       ( 'storage', 'BIG_IO',    'TRUE' )

CREATE INDEX productsindex ON products(text )INDEXTYPE IS ctxsys.context
PARAMETERS( 'section group sec_grp storage storage' );

-- First we'll look at a simple query using a faceted search
-- The user has chosen cameras with 10MP resolution and price in cat 100-150 or 150-200

SELECT * FROM products WHERE CONTAINS( text, 'nikon AND MVAND(facetlist, (1) ) AND MVOR(facetlist, (5,6))') > 0;

-- But how do we get back facet information from a query?  One way is to use the CONTAINS clause again,
-- but have a query template including a result set descriptor. This will fetch back facet counts
-- for each facet value we specify.

-- use a SQL*Plus bind variable to hold the query template
VARIABLE query CLOB;

-- assign the query template text to the SQL*Plus variable
BEGIN
  :query := '
<query>
  <textquery>
    nikon AND MVAND( facetlist, (1) ) AND MVOR( facetlist, (5,6) )
  </textquery>
  <score datatype="INTEGER"/>
  <ctx_result_set_descriptor>
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
</query>
';
END;
/

-- the output of the query is two fold:
--   1/ We get the normal SQL "SELECT" list returned as normal
--   2/ The result set document (containing the information requested in our 
--      results set descriptor) is placed in public variable in the 
--      ctx_query package - ctx_query.result_set_document.
-- it is necessary to create temporary lob for that before running the query

BEGIN
  dbms_lob.createtemporary( ctx_query.result_set_document, true );
  :res := ctx_query.result_set_document;
END;
/

-- Now run the query. In this case the SELECT list is just output to the terminal
-- in an application we would have fetched this data using a cursor and displayed
-- it as the main body of our results

select * from products where contains( text, :query ) > 0;

-- Now we'll fetch the result set document. We're putting it into a XMLType column
-- in a table for convenience

BEGIN
  INSERT INTO res_output values(  xmltype( ctx_query.result_set_document ) );
END;
/

-- display the whole result set document as XML:

select res from res_output;

-- Now turn that XML back into a SQL table using XML DB functions. The application
-- could process the XML directly, but this allows us to use SQL functions, the 
-- most appropriate way of dealing with XML from SQL*Plus

-- First get the simple facet ids and counts:

SELECT rs.facet_id, rs.facet_count
 FROM res_output r, XMLTABLE 
('/ctx_result_set/groups/group'
PASSING r.res
  COLUMNS 
    facet_id     NUMBER PATH '@value',
    facet_count  NUMBER PATH 'count/text()'
) as rs;

-- Now repeat that last query, but this time join it with the facet table

-- following line just helps make display neater
break on FACET_NAME skip 1

-- This is something like what we'd want to display in our search results
-- in order to allow the user to narrow down their search:

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




