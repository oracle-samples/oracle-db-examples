set echo on

connect / as sysdba

drop user shadow cascade;

create user shadow identified by shadow;
grant connect,resource,ctxapp,unlimited tablespace,alter session to shadow;

-- allow our new user to examine the pending tables in CTXSYS schema
grant select on ctxsys.dr$pending to shadow;
grant select on ctxsys.dr$online_pending to shadow;

connect shadow/shadow

-- drop table mytable;

create table mytable (text varchar2(2000));

insert into mytable values ('the cat_sat on the mat');

-- exec ctx_ddl.drop_preference   ('mypref')
exec ctx_ddl.create_preference ('mypref', 'BASIC_LEXER')
exec ctx_ddl.set_attribute     ('mypref', 'PRINTJOINS', '_')

create index myindex on mytable(text) indextype is ctxsys.context parameters ('lexer mypref sync(manual)');

alter session set events '10046 trace name context forever, level 4';

exec ctx_ddl.create_shadow_index('myindex', 'replace NOPOPULATE');

select table_name from user_tables;

declare
  idxid integer;
begin
  -- figure out shadow index name 
  select idx_id into idxid from ctx_user_indexes
     where idx_name ='MYINDEX';
  -- populate pending
  ctx_ddl.populate_pending('RIO$'||idxid);
  -- non time limited sync : can use an extra time param and repeat if required
  ctx_ddl.sync_index(idx_name =>'RIO$'||idxid);
end;
/

-- do an update
update mytable set text = 'the cat sat on the dog';

-- and an insert
insert into mytable values ('a new row');

commit;

-- Check the rowids of the two rows
select rowid, text from mytable

-- now check pending and online_pending

select pnd_cid, pnd_rowid from ctxsys.dr$pending;

select onl_cid, onl_rowid from ctxsys.dr$online_pending;

-- do a SYNC on the old index

exec ctx_ddl.sync_index('myindex')

-- check again
-- we should have processed the rows from pending but online_pending will remain

select pnd_cid, pnd_rowid from ctxsys.dr$pending;

select onl_cid, onl_rowid from ctxsys.dr$online_pending;

-- swap in the shadow index

exec ctx_ddl.exchange_shadow_index('MYINDEX');

-- ... and check again
-- now we should find rows have moved from online_pending to pending

select pnd_cid, pnd_rowid from ctxsys.dr$pending;

select onl_cid, onl_rowid from ctxsys.dr$online_pending;

-- now a final sync on the new index

exec ctx_ddl.sync_index('myindex')

-- and we should be all working:

select * from mytable where contains(text, 'dog OR row') > 0;
