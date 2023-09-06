-- experiments in changing how discrimating fuzzy is by altering the score
-- parameter

set echo off
set feedback off
set termout off
set verify off

drop table t;

create table t (x varchar2(40));
insert into t values ('hello');
insert into t values ('helio');
insert into t values ('helloo');
insert into t values ('hullo');
insert into t values ('helo');
insert into t values ('shello')
insert into t values ('ello');
insert into t values ('helo');
insert into t values ('hellow');

commit;

exec ctx_ddl.drop_preference('mywl');
exec ctx_ddl.create_preference('mywl', 'basic_wordlist');

create index ti on t(x) indextype is ctxsys.context
parameters ('wordlist mywl');

set termout on

-----------------------------------------

define score=55

prompt
prompt SCORE level setting is &score
prompt =========================

select score(1) as "Score" ,x as "Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) > 0 order by score(1) desc;
select score(1) as "Score" ,x as "Not Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) = 0 order by score(1) desc;

-----------------------------------------

define score=60

prompt
prompt SCORE level setting is &score
prompt =========================

select score(1) as "Score" ,x as "Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) > 0 order by score(1) desc;
select score(1) as "Score" ,x as "Not Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) = 0 order by score(1) desc;

-----------------------------------------

define score=65

prompt
prompt SCORE level setting is &score
prompt =========================

select score(1) as "Score" ,x as "Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) > 0 order by score(1) desc;
select score(1) as "Score" ,x as "Not Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) = 0 order by score(1) desc;

-----------------------------------------

define score=70

prompt
prompt SCORE level setting is &score
prompt =========================

select score(1) as "Score" ,x as "Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) > 0 order by score(1) desc;
select score(1) as "Score" ,x as "Not Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) = 0 order by score(1) desc;
-----------------------------------------

define score=75

prompt
prompt SCORE level setting is &score
prompt =========================

select score(1) as "Score" ,x as "Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) > 0 order by score(1) desc;
select score(1) as "Score" ,x as "Not Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) = 0 order by score(1) desc;

-----------------------------------------

define score=80

prompt
prompt SCORE level setting is &score
prompt =========================

select score(1) as "Score" ,x as "Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) > 0 order by score(1) desc;
select score(1) as "Score" ,x as "Not Matched" from t where contains (x, 'fuzzy(hello,&score,100,W)',1) = 0 order by score(1) desc;
