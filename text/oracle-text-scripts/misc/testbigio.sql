drop table testbigio;

create table testbigio (text varchar2(2000));
insert into testbigio values ('the quick brown fox');

exec ctx_ddl.drop_preference('bigio')
exec ctx_ddl.create_preference('bigio', 'basic_storage')

create index bioindex on testbigio(text)
indextype is ctxsys.context
parameters ('storage bigio')
/

column segment_name format a30

select table_name, s.segment_name, segment_subtype
from user_lobs b, user_segments s
where b.segment_name = s.segment_name
and b.column_name = 'TOKEN_INFO'
and b.table_name like 'DR$BIOINDEX%'
/

exec ctx_ddl.drop_preference('bigio')
exec ctx_ddl.create_preference('bigio', 'basic_storage')
exec ctx_ddl.set_attribute('bigio', 'stage_itab', 'true')
exec ctx_ddl.set_attribute('bigio', 'big_io', 'true')
exec ctx_ddl.set_attribute('bigio', 'separate_offsets', 'true')
exec ctx_ddl.set_attribute('bigio', 'i_table_clause', 'lob(token_info) store as securefile(nocompress cache)')
exec ctx_ddl.set_attribute('bigio', 'g_table_clause', 'lob(token_info) store as securefile(nocompress cache)');

create index bioindex on testbigio(text)

alter index bioindex rebuild parameters('replace metadata storage bigio');

exec ctx_output.start_log('indexrebuild.log')

exec ctx_ddl.optimize_index('bioindex', 'REBUILD')

exec ctx_output.end_log
