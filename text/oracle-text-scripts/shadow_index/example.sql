connect / as sysdba

drop user shadow cascade;

create user shadow identified by shadow;
grant connect,resource,ctxapp,unlimited tablespace,alter session to shadow;

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

insert into mytable values ('a new row');
commit;

/* swap in the shadow index */
--exec ctx_ddl.exchange_shadow_index('MYINDEX');

-- alter session set events '10046 trace name context forever, level 0';

-- check that the original lexer is still correct
--select token_text from dr$myindex$i;

