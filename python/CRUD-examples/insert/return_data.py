# Code Sample from the tutorial at https://learncodeshare.net/2015/06/26/insert-crud-using-cx_oracle/
#  section titled "Returning data after an insert"
# Using the base template, the example code executes a simple insert using positional bind variables.
#  A cursor variable is used to accept the insert statements returning value.  This value is then
#  used as the parent key value to insert a child record.

import cx_Oracle
import os
connectString = os.getenv('DB_CONNECT') # The environment variable for the connect string: DB_CONNECT=user/password@database
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

statement = 'insert into lcs_people(name, age, notes) values (:1, :2, :3) returning id into :4'
cur.execute(statement, ('Sandy', 31, 'I like horses', new_id))

sandy_id = new_id.getvalue()

pet_statement = 'insert into lcs_pets (name, owner, type) values (:1, :2, :3)'
cur.execute(pet_statement, ('Big Red', sandy_id, 'horse'))

con.commit()

print('Our new value is: ' + str(sandy_id).rstrip('.0'))

sandy_pet_statement = 'select name, owner, type from lcs_pets where owner = :owner'
cur.execute(sandy_pet_statement, {'owner': sandy_id})
res = cur.fetchall()
print('Sandy\'s pets: ')
print (res)
print(' ')

get_all_rows('New Data')
