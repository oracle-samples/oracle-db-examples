drop table t;
create table t(c varchar2(2000));
insert into t values ('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz');
insert into t values ('abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabc');
create index tc on t(c) indextype is ctxsys.context;
select token_text from dr$tc$i;
select * from t where contains(c, 'abcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyzabcdefghijklmnopqrstuvwxyz') > 0;
