drop table t;

create table t (x varchar2(2000));

insert into t values ('the quick brown fox jumps over the lazy dog');

insert into t values ('King Alexander of Macedonia was quite successful');
insert into t values ('Alexander, King of Kings');
insert into t values ('Alexander the Great, King of Kings');
insert into t values ('Alexander the Great, King of Kings - one of the Greatest kings in Persian history');
insert into t values ('alexander the great king of kings persian history');
insert into t values ('Darius was also a great king of kings in persian history');
insert into t values ('Darius was also a great k$ng of k^ngs in persian history');
insert into t values ('Alexander the Great, K$ng of K^ngs - one of the Greatest kings in Persian history');

exec ctx_ddl.drop_preference('tilp');

begin
  ctx_ddl.create_preference('tilp', 'basic_lexer');
  ctx_ddl.set_attribute('tilp', 'printjoins', '!£$^&*()[]');
end;
/

create index ti on t(x) indextype is ctxsys.context
parameters ('lexer tilp');
