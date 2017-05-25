# Code Sample from the tutorial at https://learncodeshare.net/2015/06/26/insert-crud-using-cx_oracle/
#  section titled "Extra Fun 1 & 2"
# Using the base template, the example code executes a simple insert using positional bind variables.
#  The get_all_rows function is modified to use a second connection to show how the data is seen
#  by different connections before and after a commit.

import cx_Oracle
import os
connectString = os.getenv('DB_CONNECT') # The environment variable for the connect string: DB_CONNECT=user/password@database
con = cx_Oracle.connect(connectString)

def get_all_rows(label, connection): # << Modified to use passed in connection
 # Query all rows
 cur = connection.cursor() # << cursor from passed in connection
 statement = 'select id, name, age, notes from lcs_people order by id'
 cur.execute(statement)
 res = cur.fetchall()
 print(label + ': ')
 print (res)
 print(' ')
 cur.close()

get_all_rows('Original Data', con)

# Make a second connection
con2 = cx_Oracle.connect(connectString)

cur = con.cursor()
statement = 'insert into lcs_people(name, age, notes) values (:2, :3, :4)'
cur.execute(statement, ('Suzy', 31, 'I like rabbits'))

get_all_rows('New connection after insert', con2)
get_all_rows('Same connection', con)

con.commit()

get_all_rows('New connection after commit', con2)

get_all_rows('New Data', con)
