set heading off
set verify off
set pages 0
set feedback off
set echo off
set sqlprompt 'rem '
spool delete_files.sql
select '!rm &prefix'||cache_file_path from eq_test.eq$doc where contains (cache_file_path, '&search') > 0;
spool off
set sqlprompt 'SQL> '
set feedback on
--@delete_files.sql
--delete from eq_test.eq$url 
--  where url_id in 
--    ( select url_id from eq_test.eq$doc 
--      where contains (cache_file_path, '&search') > 0
--    )
--/

exec ctx_ddl.sync_index('EQ_TEST.EQ$DOC_PATH_IDX');
!searchctl restartall
