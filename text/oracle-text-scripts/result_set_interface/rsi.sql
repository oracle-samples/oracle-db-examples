set serveroutput on size 1000000

drop table foo;

create table foo(bar clob);

insert into foo values (
'<title>the quick brown fox</title>the quick brown fox<mydate>2010-10-01</mydate>');

insert into foo values (
'<title>the fox</title>the quick brown fox fox fox <mydate>2012-10-01</mydate>');

insert into foo values (
'<title>foo bar</title>the quick brown brown fox fox fox <mydate>2011-10-01</mydate>');

exec ctx_ddl.drop_section_group('mysect')

exec ctx_ddl.create_section_group('mysect', 'BASIC_SECTION_GROUP')

exec ctx_ddl.add_sdata_section('mysect', 'title', 'title', 'CHAR')

exec ctx_ddl.add_sdata_section('mysect', 'mydate', 'mydate', 'DATE')

create index fooindex on foo(bar) indextype is ctxsys.context
parameters ('section group mysect')
/

-- normal query using templates

select score(1), substr(bar, 50) from foo where contains (bar,'
<query>
  <textquery>
    fox
  </textquery>
  <score datatype="FLOAT" normalization_expr="doc_score * ( ( sdata(mydate) - date(2009-01-01) )/365 )"/>
</query>
', 1) > 0
/

-- result set interface

variable rs_output clob;

declare
  rs_descriptor clob;
  qry varchar2(4000);
begin
  qry := 'fox';
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
