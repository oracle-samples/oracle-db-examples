drop table t;

create table t (id varchar2(20) primary key, text varchar2(2000));

insert into t values ('1', 'the cat cat cat dog dog sat on the big brown mat');
insert into t values ('2', 'the big brown mat sat on the big brown mat');

create index ti on t(text) indextype is ctxsys.context;

set serverout on size 1000000

create or replace procedure run_query (search_string varchar2) is
   highlights ctx_doc.highlight_tab;
begin
   for i in ( select id, text from t where contains (text, search_string)>0 ) loop
      ctx_doc.set_key_type('PRIMARY_KEY');
      ctx_doc.highlight(
         index_name => 'TI',
         textkey    => i.id,
         text_query => search_string,
         restab     => highlights
      );
      dbms_output.put_line( search_string || ' : record ' || i.id || ' hit count is ' || highlights.count );
   end loop;
end;
/
-- show err
set echo off
set prompt off

exec run_query('cat')
exec run_query('cat dog')
exec run_query('brown mat')
