exec ctx_ddl.drop_preference('my_basic_lexer')

BEGIN
ctx_ddl.create_preference
(
  preference_name => 'my_basic_lexer',
  object_name => 'basic_lexer'
);
ctx_ddl.set_attribute
(
  preference_name => 'my_basic_lexer',
  attribute_name => 'printjoins',
  attribute_value => '_%'
);

END;
/

drop table t1;
create table t1 (text varchar2(80));

insert into t1 values ('My example is 80% complete');
insert into t1 values ('This contains 80 without percent');
insert into t1 values ('This contains 801 without percent');
insert into t1 values ('Na%me1');
insert into t1 values ('Narme1');

CREATE INDEX t1_index ON t1 ( text )
indextype IS ctxsys.context
parameters ( 'lexer my_basic_lexer' );

select text from t1 where contains (text, '80%') > 0;
select text from t1 where contains (text, 'Na%me1') > 0;
select text from t1 where contains (text, '{80%}') > 0;
select text from t1 where contains (text, '{Na%me1}') > 0;
