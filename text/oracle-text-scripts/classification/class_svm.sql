drop table files;
create table files (doc_id number, filename varchar2(200));

drop table doc_categories;
create table doc_categories( 
  dc_doc_id   number,
  dc_category number,
  primary key (dc_category, dc_doc_id))
  organization index;

-- insert into files values   (1, 'H:\auser\Work\Code\python\sentiment\small_train\pos\foo.txt');
-- insert into doc_categories values (1, 1);
-- insert into files values   (2, 'H:\auser\Work\Code\python\sentiment\small_train\pos\bar.txt');
-- insert into doc_categories values (2, 1);
-- insert into files values   (3, 'H:\auser\Work\Code\python\sentiment\small_train\neg\text1.txt');
-- insert into doc_categories values (3, 2);
-- insert into files values   (4, 'H:\auser\Work\Code\python\sentiment\small_train\neg\text2.txt');
-- insert into doc_categories values (4, 2);

set output off
set feedback off
@h:\auser\work\code\python\sentiment\loader.sql
set feedback 2
set output on

set echo on

drop table category_descriptions;

create table category_descriptions( 
  cd_category    number,
  cd_description varchar2(80));

insert into category_descriptions values (1, 'positive');
insert into category_descriptions values (2, 'negative');

create index filesindex on files (filename) indextype is ctxsys.context
parameters ('datastore ctxsys.file_datastore');

select * from ctx_user_index_errors;
-- select token_text from dr$filesindex$i;

drop table rules;

create table rules (
 cat_id number,
 type number(3) not null,
 rule blob
);

exec ctx_ddl.drop_preference('my_classifier')
exec ctx_ddl.create_preference('my_classifier', 'SVM_CLASSIFIER')
exec ctx_ddl.set_attribute('my_classifier', 'MAX_FEATURES', '100000')

begin
  ctx_cls.train(
    index_name => 'filesindex',
    docid      => 'doc_id',
    cattab     => 'doc_categories',
    catdocid   => 'dc_doc_id',
    catid      => 'dc_category',
    restab     => 'rules',
    pref_name  => 'my_classifier'
  );
end;
/

-- select cd_description, rule_confidence, rule_text from rules, 
-- category_descriptions where cd_category = rule_cat_id;

exec ctx_ddl.drop_preference('my_filter')
exec ctx_ddl.create_preference('my_filter', 'NULL_FILTER')

create index rules_idx on rules (rule) indextype is ctxsys.ctxrule
  parameters('filter my_filter classifier my_classifier');

select count(*) from ctx_user_index_errors;

set serveroutput on

create or replace procedure sentiment(doc clob) is
begin
   for c in 
     ( select count(*) catcount, cd_description from rules, category_descriptions
       where cd_category = cat_id
       and matches (rule, doc) > 0 group by cd_description) loop
     dbms_output.put_line('CATEGORY: '||c.cd_description||' count: '||c.catcount);
   end loop;
end;
/
show err

exec sentiment('perfect performances from all the crew')
set echo off
