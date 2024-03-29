SET ECHO ON

-- uncomment next three lines to re-run the test

--exec ctx_ddl.drop_section_group('mysec');
--drop index idx;
--drop table books;

create table books(id number, info varchar2(100), price number, author varchar2(20));

exec ctx_ddl.create_section_group('mysec', 'basic_section_group');

begin
  for i in 1..99
 loop
    ctx_ddl.add_sdata_section('mysec', 's'||i, 's'||i,'number');
    insert into books values(i,'Oracle Text <age>'|| i ||' </age> '|| i ||
                               ' book <s'|| i ||'>'|| i ||' </s'|| i ||'>',
                             i*100,'An_Author');
  end loop;
end;
/

create index idx on books(info) indextype is ctxsys.context parameters('section group mysec');

-- should return id=32
select id from books where contains(info, 'Oracle and SDATA(s32=32)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
