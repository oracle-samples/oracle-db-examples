#Code Sample from the tutorial at https://learncodeshare.net/2015/07/09/delete-crud-using-cx_oracle/
#  section titled "Boilerplate template"
#The following code is used as the base template for the other examples.

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

# Your code here

get_all_rows('New Data', 'pets')
