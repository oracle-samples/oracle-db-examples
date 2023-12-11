-- source reference: https://docs.oracle.com/database/121/CCAPP/GUID-9F2196D4-C073-4B2F-A3C2-6B9369249896.htm#CCAPP9226

-- alter session set TRACEFILE_IDENTIFIER = 'svm_example';
-- alter session set events = '10046 trace name context forever, level 12'; 

set echo on timing on serveroutput on trimspool on
spool setup_svm.log

drop sequence test.abstract_seq;
-- drop index test.training_abstracts_idx;
drop table test.training_abstracts;
drop table test.testcategory;
drop table test.restab;
exec ctx_ddl.drop_preference('my_classifier');
exec ctx_ddl.drop_preference('my_filter');

create table test.testcategory (
        doc_id number, 
        cat_id number, 
        cat_name varchar2(100)
         );


create table test.training_abstracts ( docid number primary key, abstract CLOB );
create sequence test.abstract_seq start with 1;

insert into test.training_abstracts (select test.abstract_seq.nextval, abstract from test.brain);
insert into test.testcategory ( select docid, 1, 'Brain' from test.training_abstracts );

insert into test.training_abstracts (select test.abstract_seq.nextval, abstract from test.cancer);
insert into test.testcategory ( select docid, 2, 'Cancer' from test.training_abstracts where docid > (select max(doc_id) from test.testcategory) );

insert into test.training_abstracts (select test.abstract_seq.nextval, abstract from test.maternal);
insert into test.testcategory ( select docid, 3, 'Maternal' from test.training_abstracts where docid > (select max(doc_id) from test.testcategory) );

insert into test.training_abstracts (select test.abstract_seq.nextval, abstract from test.microbes);
insert into test.testcategory ( select docid, 4, 'Microbes' from test.training_abstracts where docid > (select max(doc_id) from test.testcategory) );

insert into test.training_abstracts (select test.abstract_seq.nextval, abstract from test.synmed);
insert into test.testcategory ( select docid, 5, 'SynMed' from test.training_abstracts where docid > (select max(doc_id) from test.testcategory) );


create index test.training_abstracts_idx on test.training_abstracts(abstract) indextype is ctxsys.context parameters('nopopulate');


exec ctx_ddl.create_preference('my_classifier','SVM_CLASSIFIER'); 
exec ctx_ddl.set_attribute('my_classifier','MAX_FEATURES','100');

create table test.restab (
  cat_id number,
  type number(3) not null,
  rule blob
 );

exec ctx_cls.train('training_abstracts_idx', 'docid','testcategory','doc_id','cat_id', 'restab','my_classifier');

exec ctx_ddl.create_preference('my_filter','NULL_FILTER');
create index restabx on test.restab (rule) 
       indextype is ctxsys.ctxrule 
       parameters ('filter my_filter classifier my_classifier');

commit;
spool off
