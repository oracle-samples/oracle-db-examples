set echo on

drop table mytable;
create table mytable (text varchar2(2000));


begin
  for i in 1..100000 loop
    insert into mytable values ('hello world'||i);
  end loop;
end;
/

exec ctx_ddl.drop_preference  ('mystor')
exec ctx_ddl.create_preference('mystor', 'BASIC_STORAGE')
exec ctx_ddl.set_attribute    ('mystor', 'SAVE_COPY',     'PLAINTEXT')
-- exec ctx_ddl.set_attribute    ('mystor', 'FORWARD_INDEX', 'Y')

create index myindex on mytable (text)
indextype is ctxsys.context
parameters ('storage mystor fast_dml')
parallel 4;

select table_name from user_tables where table_name like 'DR$MYINDEX%';

-- $D contains the save copy

select docid, count(*) from dr$myindex$d group by docid having count(*) > 2;

select max(docid) from dr$myindex$d;
select max(docid) from dr$myindex$k;
