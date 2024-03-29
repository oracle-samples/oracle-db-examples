drop table foo;
drop materialized view fooview;

-- create a simple table to hold our data

create table foo(id number primary key, account number, text varchar2(2000));

-- insert some data

insert into foo values (1, '12345', 'hello world');
insert into foo values (11, '67890', 'goodbye world');

-- create a range-partitioned materialized view on the foo table
-- it contains only the id from the original table and a dummy column

create materialized view fooview 
  partition by range(id) 
     (partition p1 values less than (10), 
      partition p2 values less than (maxvalue)
     )
  refresh complete on commit
  as (select id, 'x' as dummy from foo) 
/

-- user datastore procedure which fetches data for indexing from the
-- original table

create or replace procedure my_proc 
   ( rid rowid, 
     data in out nocopy clob) is
begin
   -- loop is executed one time only as row is fetched by rowid
   for csr in (
     select  account, text
       from  foo f, fooview v
       where f.id = v.id 
       and   v.rowid = rid ) loop
     data :=         '<account>' || csr.account || '</account>';
     data := data || '<text>'    || csr.text    || '</text>';
   end loop;
end;
/
list
show errors

-- user datastore preference

exec ctx_ddl.drop_preference  ('my_ds')
exec ctx_ddl.create_preference('my_ds', 'USER_DATASTORE')
exec ctx_ddl.set_attribute    ('my_ds', 'PROCEDURE', 'my_proc')

-- section group

exec ctx_ddl.drop_section_group  ('my_sg')
exec ctx_ddl.create_section_group('my_sg', 'BASIC_SECTION_GROUP')
exec ctx_ddl.add_field_section   ('my_sg', 'account', 'account', TRUE)
exec ctx_ddl.add_field_section   ('my_sg', 'text', 'text', TRUE)

-- create the index on the materialized view

create index fooviewindex on fooview(dummy)
indextype is ctxsys.context
local
parameters (' 
  datastore     my_ds 
  section group my_sg 
  sync          (every "freq=secondly; interval=5")
');

-- finally we need a trigger to keep the index updated if any of our
-- target columns in the original table are updated

create or replace trigger trig1u
after update 
  on t1 
  for each row
begin
  if :new.col_A != :old.col_A then
     update text_table tt set col_A = :new.col_A
     where tt.id  = :new.id 
     and   tab_id = 'T1';
  end if;
  if :new.col_B != :old.col_B then
     update text_table tt set col_B = :new.col_B,
                              col_A = col_A
     where tt.id  = :new.id 
     and   tab_id = 'T1';
  end if;
end;
/


-- try some queries

select * from fooview where contains (dummy, '123456 WITHIN account') > 0;
select * from fooview where contains (dummy, '12345 WITHIN account') > 0;

-- insert a new row

insert into foo values (199, 1290, 'the quick brown fox');
commit;

-- won't have been SYNCed yet (sync is every 5 seconds)

select * from fooview where contains (dummy, 'fox WITHIN text') > 0;

-- wait 10 seconds
exec dbms_session.sleep(10)

-- try again

select * from fooview where contains (dummy, 'fox WITHIN text') > 0;

-- try updating a row

update foo set text = 'fribble' where id = 1;
commit;
exec dbms_session.sleep(10)

select * from fooview where contains (dummy, 'fribble WITHIN text') > 0;


