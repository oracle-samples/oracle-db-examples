--  First define here is the path to the cache files
define prefix=h:\oracle\oradata\ses\cache\

--  SQL*Plus shell escape char : $ for windows, ! for Linux
define shell=$

--  OS delete command : del for windows, rm for Linux
define delcmd=del

-- url is the URL to be deleted
define url=http://topics.cnn.com/topics/jennifer_hudson

set heading off
set timing off
set verify off
set pages 0
set feedback off
set echo off
set sqlprompt 'rem '
prompt Creating delete command for cache file ...
spool delete_files_tmp.sql
select '&shell &delcmd &prefix'||cache_file_path from eq_test.eq$doc where display_url='&url';
spool off
set sqlprompt 'SQL> '
set feedback on
prompt Executing delete command for cache file ...
@delete_files_tmp.sql
prompt Deleting from eq$url ...
delete from eq_test.eq$url 
  where url_id in 
    ( select url_id from eq_test.eq$doc 
      where display_url = '&url'
    )
/
prompt Deleting from eq$doc ...
delete from eq_test.eq$doc where display_url='&url';
commit;

prompt Syncing index ...
exec ctx_ddl.sync_index('EQ_TEST.EQ$DOC_PATH_IDX');
prompt Done.
