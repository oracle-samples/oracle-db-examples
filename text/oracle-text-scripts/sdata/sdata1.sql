SET ECHO ON
SET FEEDBACK 1
SET NUMWIDTH 10
SET LINESIZE 80
SET TRIMSPOOL ON
SET TAB OFF
SET PAGESIZE 100

exec ctx_ddl.drop_section_group('mysec');
drop index idx;
drop table books;

create table books(id number, info varchar2(100), price number, author varchar2(20));

exec ctx_ddl.create_section_group('mysec', 'basic_section_group');

begin
  for i in 5..10
  loop
    ctx_ddl.add_sdata_section('mysec', 's'||i, 's'||i,'VARCHAR2');
    insert into books values(i,'Oracle Text <age>'|| i ||' </age> '|| i ||
                               ' book <s'|| i ||'>'|| 'foo' ||' </s'|| i ||'>',
                             i*100,'An_Author');
  end loop;
end;
/

insert into books values(100, 'Oracle Text <s100>100</s100>', 10000,'An_Author');
-- should return DRG-12239
exec ctx_ddl.add_sdata_section('mysec', 's100','s100','number');

create index idx on books(info) indextype is ctxsys.context parameters('section group mysec');

-- should return id=32
select id from books where contains(info, 'Oracle and SDATA(s32 like ''32'')')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75 like ''75'')')>0;
-- should return DRG-10856
select id from books where contains(info, 'Oracle and SDATA(s100 like ''100'')')>0;

desc dr$idx$s
select sdata_id from dr$idx$s;
