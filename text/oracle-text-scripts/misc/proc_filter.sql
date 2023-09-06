set define off

create or replace procedure remove_broken_comments (doc_in in clob, doc_out in out nocopy clob) is
begin
 
  doc_out := regexp_replace(doc_in, '&lt;\-\-.+?\-\-&gt;', '');

end;
/
show errors

drop table t;

create table t (x clob);

insert into t values ('<title>doc title</title>some random text &lt;-- a comment --&gt; some arbitrary text &lt-- more comments --&gt; endofdoc ');

exec ctx_ddl.drop_preference('my_proc_filter')
exec ctx_ddl.create_preference('my_proc_filter', 'procedure_filter')

exec ctx_ddl.set_attribute('my_proc_filter', 'procedure', 'remove_broken_comments')
exec ctx_ddl.set_attribute('my_proc_filter', 'input_type',        'CLOB')
exec ctx_ddl.set_attribute('my_proc_filter', 'output_type',       'CLOB')
exec ctx_ddl.set_attribute('my_proc_filter', 'rowid_parameter',   'FALSE')
exec ctx_ddl.set_attribute('my_proc_filter', 'charset_parameter', 'FALSE')

create index ti on t(x) indextype is ctxsys.context
parameters ('section group ctxsys.html_section_group filter my_proc_filter');

-- any errors calling the proc will be in ctx_user_index_errors
select * from ctx_user_index_errors;

select * from t where contains (x, 'title') > 0;
select * from t where contains (x, 'random') > 0;
select * from t where contains (x, 'arbitrary') > 0;
select * from t where contains (x, 'comment') > 0;
select * from t where contains (x, 'comments') > 0;
select * from t where contains (x, 'endofdoc') > 0;
