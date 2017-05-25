# Code Sample from the tutorial at https://learncodeshare.net/2015/06/26/insert-crud-using-cx_oracle/
#  section titled "Simple insert"
# Using the base template, the example code executes a simple insert using positional bind variables.

import cx_Oracle
import os
connectString = os.getenv('db_connect')
con = cx_Oracle.connect(connectString)

def get_all_rows(label):
 # Query all rows
 cur = con.cursor()
 statement = 'select id, name, age, notes from lcs_people order by id'
 cur.execute(statement)
 res = cur.fetchall()
 print(label + ': ')
 print (res)
 print(' ')
 cur.close()

get_all_rows('Original Data')

cur = con.cursor()
statement = 'insert into lcs_people(name, age, notes) values (:2, :3, :4)'
cur.execute(statement, ('Sandy', 31, 'I like horses'))
con.commit()

get_all_rows('New Data')
