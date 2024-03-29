column stat format a30
select substr(n.name,1,30) stat, 
       rpad((s.value/1024)/1024,4) Megs
from v$sesstat s, v$statname n, v$session e
where s.STATISTIC# in (20,21,25,26) and
s.STATISTIC# = n.STATISTIC# and
e.sid = s.sid and
e.username = 'MEDLIN2';
