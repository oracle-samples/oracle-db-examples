#------------------------------------------------------------------------------
# Copyright (c) 2020, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# json_direct.py
#   Shows some JSON features of Oracle Database 21c.
#   See https://www.oracle.com/pls/topic/lookup?ctx=dblatest&id=ADJSN
#
#   For JSON with older databases see json_blob.py
#------------------------------------------------------------------------------

import sys
import json
import cx_Oracle as oracledb
import sample_env

connection = oracledb.connect(sample_env.get_main_connect_string())

client_version = oracledb.clientversion()[0]
db_version = int(connection.version.split(".")[0])

# this script only works with Oracle Database 21

if db_version < 21:
    sys.exit("This example requires Oracle Database 21.1 or later. "
             "Try json_blob.py")

# Create a table

cursor = connection.cursor()
cursor.execute("""
        begin
            execute immediate 'drop table customers';
        exception when others then
            if sqlcode <> -942 then
                raise;
            end if;
        end;""")
cursor.execute("""
        create table customers (
            id integer not null primary key,
            json_data json
        )""")

# Insert JSON data

data = dict(name="Rod", dept="Sales", location="Germany")
inssql = "insert into customers values (:1, :2)"
if client_version >= 21:
    # Take advantage of direct binding
    cursor.setinputsizes(None, oracledb.DB_TYPE_JSON)
    cursor.execute(inssql, [1, data])
else:
    # Insert the data as a JSON string
    cursor.execute(inssql, [1, json.dumps(data)])

# Select JSON data

sql = "SELECT c.json_data FROM customers c"
if client_version >= 21:
    for j, in cursor.execute(sql):
        print(j)
else:
    for j, in cursor.execute(sql):
        print(json.loads(j.read()))

# Using JSON_VALUE to extract a value from a JSON column

sql = """SELECT JSON_VALUE(json_data, '$.location')
         FROM customers
         OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY"""
for r in cursor.execute(sql):
    print(r)

# Using dot-notation to extract a value from a JSON column

sql = """SELECT c.json_data.location
         FROM customers c
         OFFSET 0 ROWS FETCH NEXT 1 ROWS ONLY"""
if client_version >= 21:
    for j, in cursor.execute(sql):
        print(j)
else:
    for j, in cursor.execute(sql):
        print(json.loads(j.read()))

# Using JSON_OBJECT to extract relational data as JSON

sql = """SELECT JSON_OBJECT('key' IS d.dummy) dummy
         FROM dual d"""
for r in cursor.execute(sql):
    print(r)
