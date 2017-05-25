# Code Sample from the tutorial at https://learncodeshare.net/2015/07/09/delete-crud-using-cx_oracle/
#  section titled "Deleting records referenced by Foreign Keys" 1st example
# Using the base template, the example code executes a simple delete using named bind variables.
#  When following the tutorial with default data this section intentionally throws an error
#  to demonstrate foreign key functionality.

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

get_all_rows('Original People Data', 'people')
get_all_rows('Original Pet Data', 'pets')

cur = con.cursor()
statement = 'delete from lcs_people where id = :id'
cur.execute(statement, {'id':1})
con.commit()

get_all_rows('New People Data', 'people')
get_all_rows('New Pet Data', 'pets')
