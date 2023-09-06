drop table foo;

create table foo(id number, bar varchar2(40));

begin
  for i in 1..69999 loop
    insert into foo values (i, 'hello world'||i);
  end loop;
end;
/

create index fooindex on foo(bar) indextype is ctxsys.context;

select row_no, length(data) from dr$fooindex$r;

@dumpDollarRLastRow.sql

select id, bar, rowid from foo where id > 70000;
