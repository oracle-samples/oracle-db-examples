#Code Sample from the tutorial at https://learncodeshare.net/2015/06/02/select-crud-using-cx_oracle/
#  section titled "Select specific rows"
#Using the base template, the example code executes a simple query using named bind variables,
#  uses fetchall to retrieve the data and displays the results.

import cx_Oracle
import os
connectString = os.getenv('dd_connect')
con = cx_Oracle.connect(connectString)

# Query for Kim
cur = con.cursor()
person_name = 'Kim'
statement = 'select id, name, age, notes from lcs_people where name = :name'
cur.execute(statement, {'name':person_name})
res = cur.fetchall()
print (res)
