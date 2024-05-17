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
  for i in 1..99
 loop
    ctx_ddl.add_sdata_section('mysec', 's'||i, 's'||i,'number');
    insert into books values(i,'Oracle Text <age>'|| i ||' </age> '|| i ||
                               ' book <s'|| i ||'>'|| i ||' </s'|| i ||'>',
                             i*100,'An_Author');
  end loop;
end;
/

insert into books values(100, 'Oracle Text <s100>100</s100>', 10000,'An_Author');
-- should return DRG-12239
exec ctx_ddl.add_sdata_section('mysec', 's100','s100','number');

create index idx on books(info) indextype is ctxsys.context parameters('section group mysec');

-- should return id=32
select id from books where contains(info, 'Oracle and SDATA(s32=32)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return DRG-10856
select id from books where contains(info, 'Oracle and SDATA(s100=100)')>0;

declare
myrowid rowid;
begin
select rowid into myrowid from books where id=75;
ctx_ddl.update_sdata(idx_name=>'idx',
        section_name=>'s75',
        sdata_value=>sys.anydata.convertnumber('9999'),
        sdata_rowid=>myrowid,
        part_name=>NULL);
end;
/

-- no rows selected
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;

rollback;

-- should retuen id=75
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- no rows selected
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;

declare
myrowid rowid;
begin
select rowid into myrowid from books where id=75;
ctx_ddl.update_sdata(idx_name=>'idx',
        section_name=>'s75',
        sdata_value=>sys.anydata.convertnumber('9999'),
        sdata_rowid=>myrowid,
        part_name=>NULL);
end;
/

-- no rows selected
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;

commit;
-- no rows selected
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;

-- should return DRG-12239
alter index idx parameters('add sdata section s101 tag s101 datatype number');

insert into books values(5100, 'Oracle Text <s10>10</s10>', 510000,'An_Author');

exec ctx_ddl.sync_index('idx');

-- should return id=10,5100
select id from books where contains(info, 'Oracle and SDATA(s10=10)')>0 order by id;
-- no rows selected
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;

exec ctx_ddl.optimize_index('idx', 'full');

-- should return id=10,5100
select id from books where contains(info, 'Oracle and SDATA(s10=10)')>0 order by id;
-- no rows selected
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;

exec ctx_ddl.optimize_index('idx', 'rebuild');

-- should return id=10,5100
select id from books where contains(info, 'Oracle and SDATA(s10=10)')>0 order by id;
-- no rows selected
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return id=75
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;


exec ctx_ddl.remove_section('mysec','s75');

alter index idx rebuild parameters('replace section group mysec');

-- should return id=32
select id from books where contains(info, 'Oracle and SDATA(s32=32)')>0;
-- should return DRG-10856
select id from books where contains(info, 'Oracle and SDATA(s75=75)')>0;
-- should return DRG-10856
select id from books where contains(info, 'Oracle and SDATA(s75=9999)')>0;
-- should return DRG-10856
select id from books where contains(info, 'Oracle and SDATA(s100=100)')>0;

exec ctx_ddl.drop_section_group('mysec');
drop index idx;
drop table books;
