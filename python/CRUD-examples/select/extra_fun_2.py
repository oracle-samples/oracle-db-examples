#Code Sample from the tutorial at https://learncodeshare.net/2015/06/02/select-crud-using-cx_oracle/
#  section titled "Extra Fun 2"
#Using the base template, the example code executes a simple query using named bind variables,
#  uses fetchall to retrieve the data and displays the results.

import cx_Oracle
import os
connectString = os.getenv('dd_connect')
con = cx_Oracle.connect(connectString)

cur = con.cursor()
person_age = 30
statement = 'select id, name, age, notes from lcs_people where age > :age'
cur.execute(statement, {'age':person_age})
res = cur.fetchall()
print (res)
