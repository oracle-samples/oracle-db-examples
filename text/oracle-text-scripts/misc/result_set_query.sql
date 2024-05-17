set serveroutput on

drop table testtable;
create table testtable(text varchar2(2000));
insert into testtable values ('
idccontenttrue 
<sdDrillDown>XXX</sdDrillDown>
<dId>diddy1</dId>
<sddDocName>foo.txt</sddDocName>
<dInDate>17-AUG-12</dInDate>
');

exec ctx_ddl.drop_section_group  ( 'mysg' )
exec ctx_ddl.create_section_group( 'mysg', 'BASIC_SECTION_GROUP' )
exec ctx_ddl.add_sdata_section   ( 'mysg', 'sdDrillDown', 'sdDrillDown' )
exec ctx_ddl.add_sdata_section   ( 'mysg', 'dId', 'dId' )
exec ctx_ddl.add_sdata_section   ( 'mysg', 'sddDocName', 'sddDocName' )
exec ctx_ddl.add_sdata_section   ( 'mysg', 'dInDate', 'dInDate', 'DATE' )

create index FT_IdcText1 on testtable( text ) indextype is ctxsys.context
parameters( 'section group mysg' )
/

variable outputclob clob;

declare 
  indexn varchar2(30);
  query  varchar2(80);
  rsd    clob;
  outc   clob;
begin
  indexn := 'FT_IdcText1';
  query  := 'idccontenttrue';
  rsd    := '
<ctx_result_set_descriptor>
  <count exact="false"/>
  <group sdata="sdDrillDown">
    <count exact="true"/>
  </group>
  <hitlist start_hit_num="1" end_hit_num="20" order="dInDate Desc">
    <sdata name="dID"/><sdata name="sddDocName"/>
    <score />
  </hitlist>
</ctx_result_set_descriptor>
';
  -- Allocate the output clob
  dbms_lob.createtemporary( outc, true );
  -- Get the result set
  ctx_query.result_set( indexn, query, rsd, outc, null );
  -- List it
  dbms_output.put_line( outc );
  -- Put it into SQL*Plus variable so we can pretty-print it
  :outputclob := outc;
end;
/

-- pretty-print the XML output via an XMLType column

drop table xmltemp;
create table xmltemp( xml_text xmltype );
insert into xmltemp values( xmltype(:outputclob) );

set long 500000
set pagesize 50

select * from xmltemp;

