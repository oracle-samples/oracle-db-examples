@@snap
declare 
  n1 number(10);
  n2 number(10);
begin
  for i in 1..100
  loop
     execute immediate 
       'select /*+ NO_ADAPTIVE_PLAN */ sum(t1.c), sum(t2.c) from t1, t2 where t1.a = t2.a and t1.d = 10' into n1,n2;
  end loop;
end;
/
@@snap
