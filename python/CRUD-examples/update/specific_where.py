# Code Sample from the tutorial at https://learncodeshare.net/2015/07/02/update-crud-using-cx_oracle/
#  section titled "Make sure your where clause is specific"
# Using the base template, the example code executes a simple update using positional bind variables.

import cx_Oracle
import os
connectString = os.getenv('db_connect')
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
statement = 'update lcs_pets set owner = :1 where owner = :2 and type = :3'
cur.execute(statement, (2, 1, 'dog'))
con.commit()

get_all_rows('New Data', 'pets')
