drop table foo;
create table foo (bar varchar2(2000));
insert into foo values ('<text>blah blah <catid>2</catid> blah blah</text>');
insert into foo values ('<text>blah blah <catid>3</catid> blah blah</text>');
insert into foo values ('<text>blah blah <catid>4</catid> blah blah</text>');

exec ctx_ddl.drop_section_group   ('mysections')
exec ctx_ddl.create_section_group ('mysections', 'basic_section_group')
exec ctx_ddl.add_field_section    ('mysections', 'catid', 'catid')

create index fooindex on foo(bar) indextype is ctxsys.context parameters ('section group mysections');

select rowid, bar from foo where contains (bar, '(1,2,3) within catid') > 0;

REM method 1

select rowid, x.catid from 
  foo, xmltable('/'
   passing xmltype(foo.bar)
   columns
    catid VARCHAR2(20) PATH 'catid'
   ) as x
  where contains (bar, '(1,2,3) within catid') > 0
/

REM method 2

create table highlight_tab (
  query_id number,
  offset   number,
  length   number )
/

set serveroutput on

begin
  for c in ( 
    select rowid, bar from foo 
    where contains (bar, '(1,2,3) within catid') > 0 )
  loop
    ctx_doc.set_key_type('ROWID');
    execute immediate('truncate highlight_tab');
    ctx_doc.highlight(
        index_name => 'fooindex',
        textkey    => rowidToChar(c.rowid),
        text_query => '(1,2,3) within catid',
        restab     => 'highlight_tab',
        query_id   => null  -- don't share results table
      );
    for c2 in (select offset, length from highlight_tab) loop
      dbms_output.put_line( 'Rowid: '||c.rowid||' catid '||
        substring(c.bar, c2.offset, c2.length) );
    end loop;
  end loop;
end;
/

    