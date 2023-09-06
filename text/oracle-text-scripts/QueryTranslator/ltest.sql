@parser2

exec ubparse.test

column x format a65
variable q varchar2(4000);

select * from qlog;

begin select text into :q from qlog; end;
/
select score(1),x from t where contains (x,:q, 1) > 0 order by score(1) desc;
