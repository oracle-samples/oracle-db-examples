column table_name format a30
column extension_name format a50
column extension format a20
select table_name,extension_name,extension from user_stat_extensions order by table_name;
