# Code Sample from the tutorial at https://learncodeshare.net/2015/06/02/select-crud-using-cx_oracle/
#  section titled "Simple query"
# Using the base template, the example code executes a simple query, uses fetchall to retrieve the data
#  and displays the results.

import cx_Oracle
import os
connectString = os.getenv('DB_CONNECT') # The environment variable for the connect string: DB_CONNECT=user/password@database
con = cx_Oracle.connect(connectString)

# Query all rows
cur = con.cursor()
statement = 'select id, name, age, notes from lcs_people'
cur.execute(statement)
res = cur.fetchall()
print (res)
