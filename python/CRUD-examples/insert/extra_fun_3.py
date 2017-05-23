#Code Sample from the tutorial at https://learncodeshare.net/2015/06/26/insert-crud-using-cx_oracle/
#  section titled "Extra Fun 3"
#Using the base template, the example code executes a simple insert using positional bind variables.
#  Cursor variables are used to accept the insert statements returning values.

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

new_id = cur.var(cx_Oracle.NUMBER)
new_name = cur.var(cx_Oracle.STRING)

statement = 'insert into lcs_people(name, age, notes) values (:1, :2, :3) returning id, name into :4, :5'
cur.execute(statement, ('Sandy', 31, 'I like horses', new_id, new_name))

sandy_id = new_id.getvalue()
sandy_name = new_name.getvalue()

con.commit()

print('Our new id is: ' + str(sandy_id).rstrip('.0') + ' name: ' + str(sandy_name))

get_all_rows('New Data')
