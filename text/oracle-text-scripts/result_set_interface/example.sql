set serveroutput on size 1000000

drop table foo;

create table foo(id number, bar clob, extracol varchar2(10));

insert into foo values (1, 
'<title>the quick brown fox</title>the quick brown fox<mydate>2010-10-01</mydate>', 'ABC' );

insert into foo values (2, 
'<title>the fox</title>the quick brown fox fox fox <mydate>2012-10-01</mydate>', 'DEF' );

insert into foo values (3,
'<title>foo bar</title>the quick brown brown fox fox fox <mydate>2011-10-01</mydate>', 'GHI');

exec ctx_ddl.drop_section_group  ( 'mysect')
exec ctx_ddl.create_section_group( 'mysect', 'BASIC_SECTION_GROUP' )
exec ctx_ddl.add_sdata_section   ( 'mysect', 'title',       'title',       'CHAR' )
exec ctx_ddl.add_sdata_section   ( 'mysect', 'mydate',      'mydate',      'DATE' )

-- this line makes sure our FILTER BY column can be queries as an SDATA field:
exec ctx_ddl.add_sdata_column    ( 'mysect', 'extracol', 'extracol' )

-- create the index.  Extracol is a FILTER BY column so will be used as an SDATA field

create index fooindex on foo(bar) indextype is ctxsys.context
filter by extracol
parameters ('section group mysect')
/

-- result set interface
-- this first query will return only 1 hit in the hitlist with extracol='ABC'

variable rs_output clob;

declare
  rs_descriptor clob;
  qry varchar2(4000);
begin
  qry := 'fox AND SDATA(extracol = ''ABC'')';
  rs_descriptor := '
<ctx_result_set_descriptor>
  <hitlist start_hit_num="1" end_hit_num="10" order="SCORE DESC">
    <rowid />
    <sdata name="title" />
  </hitlist>
  <count />
  <group sdata="title">
    <count exact="true"/>
  </group>
</ctx_result_set_descriptor>
';
  dbms_lob.createtemporary( :rs_output, true );
  ctx_query.result_set( 'fooindex', qry, rs_descriptor, :rs_output );
end;
/

set pagesize 0
set long 5000000

select xmltype(:rs_output) from dual;

-- now update the FILTERBY column for row 2

update foo set extracol='ABC' where id = 2;
commit;

-- and rerun the query.  This will now return two rows in the hitlist

variable rs_output clob;

declare
  rs_descriptor clob;
  qry varchar2(4000);
begin
  qry := 'fox AND SDATA(extracol = ''ABC'')';
  rs_descriptor := '
<ctx_result_set_descriptor>
  <hitlist start_hit_num="1" end_hit_num="10" order="SCORE DESC">
    <rowid />
    <sdata name="title" />
  </hitlist>
  <count />
  <group sdata="title">
    <count exact="true"/>
  </group>
</ctx_result_set_descriptor>
';
  dbms_lob.createtemporary( :rs_output, true );
  ctx_query.result_set( 'fooindex', qry, rs_descriptor, :rs_output );
end;
/

set pagesize 0
set long 5000000

select xmltype(:rs_output) from dual;
