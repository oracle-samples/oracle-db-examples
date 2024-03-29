drop table foo;

create table foo (fooid number, col1 varchar2(20), col2 varchar2(20), col3 varchar2(20));
insert into foo values (1, 'hello', 'cruel', 'world');
insert into foo values (2, 'quick', 'brown', 'fox');

drop table bar;

create table bar (foo_fooid number, bar1 varchar2(20));
insert into bar values (1, 'wibble');
insert into bar values (2, 'wobble');

create or replace procedure mystore (rid in rowid, vc in out varchar2) is
begin
   select 
          '<col1>'||col1||'</col1>'||
          '<col2>'||col2||'</col2>'||
          '<col3>'||col3||'</col3>'||
          '<bar1>'||bar1||'</bar1>'
     into 
          vc
     from 
          foo f, bar b
     where 
          f.fooid = b.foo_fooid
          and f.rowid = rid;
end;
/
show err

exec ctx_ddl.drop_preference('uds')
exec ctx_ddl.create_preference('uds', 'user_datastore')
exec ctx_ddl.set_attribute('uds', 'procedure', 'mystore')
exec ctx_ddl.set_attribute('uds', 'output_type', 'varchar2')

exec ctx_ddl.drop_section_group('sg')
exec ctx_ddl.create_section_group('sg', 'auto_section_group')

create index fooindex on foo(col1) indextype is ctxsys.context
parameters ('datastore uds section group sg sync (on commit)');

select col1 from foo where contains (col1, 'world') > 0;

create or replace trigger footrigger
before update of col2, col3 on foo
for each row
begin
  :new.col1 := :new.col1;
end;
/

create or replace trigger bartrigger
before update of bar1 on bar
for each row
begin
  update foo set col1 = col1;
end;
/

update foo set col2 = 'kind' where fooid = 1;

commit;

select col1 from foo where contains (col1, 'kind') > 0;

update foo set col3 = 'universe' where fooid = 2 ;

commit;

select col1 from foo where contains (col1, 'universe') > 0;

select col1 from foo where contains (col1, 'universe within col3') > 0;

select col1 from foo where contains (col1, 'wibble') > 0;

update bar set bar1 = 'flibble' where foo_fooid = 2;
commit;

select col1 from foo where contains (col1, 'flibble within bar1') > 0;
