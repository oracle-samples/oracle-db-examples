#-- DISCLAIMER:
#-- This script is provided for educational purposes only. It is
#-- NOT supported by Oracle World Wide Technical Support.
#-- The script has been tested and appears to work as intended.
#-- You should always run new scripts initially
#-- on a test instance.

import cx_Oracle

dsn_tns = cx_Oracle.makedsn('myusserver', 7796, 'npbr')

db = cx_Oracle.connect('adhoc', 'adhoc', dsn_tns)

db.autocommit = False

print db.version

stats = db.cursor()
stats.prepare("select name,value from v$mystat m, v$statname n where m.statistic# = n.statistic# "
+ "and name in ('parse count (hard)','parse count (total)','user commits','execute count',"
+ "'bytes received via SQL*Net from client','bytes sent via SQL*Net to client',"
+ "'bytes via SQL*Net vector from client','bytes via SQL*Net vector to client',"
+ "'SQL*Net roundtrips to/from client') order by name")
stats.execute(None)
print(stats.fetchall())

#cursor = db.cursor()
#cursor.prepare('insert into ins values (:p1,:p2,:p3)') 
#named_params = {'p1':50, 'p2':'A', 'p3':'B'}
#cursor.execute(None,named_params)

db.commit()

cursorm = db.cursor()
cursorm.prepare('insert into ins values (:p1,:p2,:p3)') 
ROWS = []
for y in range(0,10):
    ROWS.append((50,'X','Y'))

cursorm.executemany(None,ROWS)

db.commit()

stats.execute(None)
print(stats.fetchall())

db.close()
