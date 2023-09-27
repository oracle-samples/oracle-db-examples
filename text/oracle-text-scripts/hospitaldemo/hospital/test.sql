set echo off
set define off

prompt SQL>  connect system/oracle
connect system/oracle

prompt SQL>  drop user enttest cascade;
drop user enttest cascade;

prompt SQL>  create user enttest identified by enttest default tablespace users temporary tablespace temp;
create user enttest identified by enttest default tablespace users temporary tablespace temp;

prompt SQL>  grant connect,resource,ctxapp,create any directory to enttest;
grant connect,resource,ctxapp,create any directory to enttest;

prompt press enter..
--pause

prompt SQL>  connect enttest/enttest
connect enttest/enttest

prompt SQL>  create table docs( id number primary key, txt clob );
create table docs( id number primary key, txt clob );

prompt inserting document...

insert into docs values (1, 'stock climbed 5 percent here');


set long 50000
set pagesize 60

select txt from docs;

prompt SQL>  create table entities( id number primary key, ents clob );
create table entities( id number primary key, ents xmltype );

prompt press enter...
--pause

prompt SQL>  exec ctx_entity.create_extract_policy( 'p1' );
exec ctx_entity.create_extract_policy( 'p1' );

prompt press enter...
--pause

declare
  mydoc clob;
  myresults clob;
begin

  --put input document into mydoc
  select txt into mydoc from docs where id=1;

  --add a new rule to identify increases (eg stock indices)
  ctx_entity.add_extract_rule('p1', 1,
    '<rule>'                                                          ||
      '<expression>'                                                  ||
         '((climbed|jumped) \d+(\.\d+)? percent)'                     ||
      '</expression>'                                                 ||
      '<type refid="1">xPositiveGain</type>'                          ||
    '</rule>');
  
  ctx_entity.compile('p1');

  --run extraction using policy p1
  ctx_entity.extract('p1', mydoc, null, myresults);

  --save entities to table
  insert into entities values(1, xmltype(myresults));
  commit;

end;
.

list
/
prompt press enter...
pause

prompt SQL>  select * from entities;
select * from entities;

column type format a20
column text format a25
column source format a20

set echo on
 
select foo.offset, foo.text, foo.type, foo.source
from entities e,
xmltable( '/entities/entity'
PASSING e.ENTS
  COLUMNS 
    offset number       PATH '@offset',
    lngth number        PATH '@length',
    text   varchar2(50) PATH 'text/text()',
    type   varchar2(50) PATH 'type/text()',
    source varchar2(50) PATH '@source'
) as foo order by offset;


set echo off
set feedback off
prompt press enter...
--pause

@proc_entities

set feedback 2

prompt SQL>  select entdemo.write_the_clob( entdemo.proc_entities( txt ), 'test2.html' ) from docs where id = 1;
select entdemo.write_the_clob( entdemo.proc_entities( txt ), 'test.html' ) from docs;


