set echo on
set serverout on

drop table t1;
create table t1(id number, text varchar2(100));

insert into t1 values (1, 'Oracle Text Sebastian');

exec ctx_ddl.drop_preference('us_lexer');
exec ctx_ddl.create_preference('us_lexer', 'basic_lexer');
create index idx on t1(text) indextype is ctxsys.context
parameters ('lexer us_lexer');


begin
  ctx_ddl.create_shadow_index('idx', 'replace NOPOPULATE');
end;
/

declare
  idxid number;
begin
  select idx_id into idxid from ctx_user_indexes where idx_name = 'IDX';
  insert into t1 values (2, 'San Diego Airport');
  insert into t1 values (3, 'Oracle Text Saurabh');
  commit;
  ctx_ddl.populate_pending('RIO$'||idxid);
end;
/

select id, rowid from t1;

column pnd_index_name format a30;

select pnd_index_name, pnd_rowid from ctx_user_pending p, t1 t
where t.rowid = p.pnd_rowid;

set head off
set feedback off
set pages 0
set echo off
spool fetchk.sql
select 'select textkey as "textkeys from RIO" from dr$rio$'||idx_id||'$k;' from ctx_user_indexes where idx_name = 'IDX';
spool off
@fetchk
set head on
set feedback on
set pages 50
set echo on

declare
  idxid number;
begin
  select idx_id into idxid from ctx_user_indexes where idx_name = 'IDX';
  CTX_ddl.sync_index('RIO$'||idxid, maxtime=>480);
end;
/

select pnd_index_name, pnd_rowid from ctx_user_pending p, t1 t
where t.rowid = p.pnd_rowid;

@fetchk

-- select table_name from user_tables;

col text format a50
select id, text from t1 where contains(text, 'Text')>0;

exec ctx_ddl.exchange_shadow_index('idx');
exec ctx_ddl.sync_index('idx');

select id, text from t1 where contains(text, 'Text')>0;
