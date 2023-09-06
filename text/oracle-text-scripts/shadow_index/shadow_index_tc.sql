connect / as sysdba

drop user claro cascade;

grant connect,resource,dba to claro identified by claro;

connect claro/claro

create table quick ( 
    quick_id                number
    constraint quick_pk     primary key,
    text                    varchar(20)); 
    
begin
for i in 1..20 loop
insert into quick values (i,'test t1xx'||i||'xxt1');
commit;
end loop;
end;
/

CREATE INDEX quick_text
  on quick ( text ) 
INDEXTYPE IS CTXSYS.CONTEXT;

-- which rows are searchable? 
-- we expect all rows
select quick_id, text from quick where CONTAINS(text,'test') > 0
order by 1;

-- Modify table to add LANG column
alter table quick add(lang varchar2(10) default 'us');

-- Start CREATE SHADOW INDEX process

exec ctx_ddl.create_preference('us_lexer','basic_lexer');
exec ctx_ddl.create_preference('e_lexer','basic_lexer');
exec ctx_ddl.set_attribute('e_lexer','base_letter','yes');
exec ctx_ddl.create_preference('m_lexer','multi_lexer');
exec ctx_ddl.add_sub_lexer('m_lexer','default','us_lexer');
exec ctx_ddl.add_sub_lexer('m_lexer','e','e_lexer');

exec ctx_ddl.create_shadow_index('quick_text', 'replace lexer m_lexer language column lang NOPOPULATE');

-- what indexes currently exist in my schema?
-- Take note of these!
select idx_id, idx_name from ctx_user_indexes;

col idx_id new_value idxid
-- figure out shadow index name
select idx_id, idx_name from ctx_user_indexes where idx_name ='QUICK_TEXT';

-- populate pending
exec ctx_ddl.populate_pending('RIO$'||&idxid)

-- how many rows to sync?
select pnd_index_name, count(*) from ctx_user_pending group by pnd_index_name;

-- sync twice only
exec ctx_ddl.sync_index(idx_name =>'RIO$'||&idxid, maxtime =>0.005)
exec ctx_ddl.sync_index(idx_name =>'RIO$'||&idxid, maxtime =>0.005)

-- how many left to sync onto the SHADOW INDEX?
select pnd_index_name, count(*) from ctx_user_pending group by pnd_index_name;

-- prematurely swap in the shadow index 
exec ctx_ddl.exchange_shadow_index('quick_text');

-- which rows are searchable now?
select quick_id, text from quick where CONTAINS(text,'test') > 0
order by 1;

-- The "lost" pending rows are left "orphaned" in dr$pending
select pnd_cid, count(*) from ctxsys.dr$pending group by pnd_cid;

-- Sync'ing will not get these rows back as they no longer correspond to
-- any existing index:

select idx_id, idx_name from ctx_user_indexes;
select idx_id, idx_owner#, idx_name from ctxsys.dr$index order by 1;



