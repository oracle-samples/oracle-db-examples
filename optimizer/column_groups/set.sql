column sqlset_name format a30
column sql_text format a100
select sqlset_name,sql_text from dba_sqlset_statements
where sql_text like '%STS MY_TEST_QUERY%'
/
