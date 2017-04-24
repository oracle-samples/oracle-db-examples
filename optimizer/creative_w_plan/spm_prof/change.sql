insert into sales
select level, sysdate+1000-rownum/1000
from   dual
connect by level <= 500000
/

commit;

insert into sales
select level, sysdate+1000-rownum/1000
from   dual
connect by level <= 500000
/

commit;

--insert into sales values (100000, to_date(sysdate+1000));
--commit;

--
-- Make sure that we don't let histograms help us out here
--
exec dbms_stats.gather_table_stats(user, 'sales', method_opt=>'for all columns size 1')


