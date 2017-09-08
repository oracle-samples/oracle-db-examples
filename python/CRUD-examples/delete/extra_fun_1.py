# Code Sample from the tutorial at https://learncodeshare.net/2015/07/09/delete-crud-using-cx_oracle/
#  section titled "Extra Fun 1"
# Using the base template, the example code executes a simple delete using named bind variables.

import cx_Oracle
import os
connectString = os.getenv('DB_CONNECT') # The environment variable for the connect string: DB_CONNECT=user/password@database
con = cx_Oracle.connect(connectString)

def get_all_rows(label, data_type='people'):
 # Query all rows
 cur = con.cursor()
 if (data_type == 'pets'):
    statement = 'select id, name, owner, type from lcs_pets order by owner, id'
 else:
    statement = 'select id, name, age, notes from lcs_people order by id'
 cur.execute(statement)
 res = cur.fetchall()
 print(label + ': ')
 print (res)
 print(' ')
 cur.close()

get_all_rows('Original Data', 'pets')

cur = con.cursor()
statement = 'delete from lcs_pets where type = :type'
cur.execute(statement, {'type':'bird'})
con.commit()

get_all_rows('New Data', 'pets')
