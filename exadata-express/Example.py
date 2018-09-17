#------------------------------------------------------------------------------
# Example.py
#
# Demonstrate how to perform a database insert and query with Python
# in Oracle Database Cloud services such as Exadata Express,
# Autonomous Transaction Processing, Autonomous Data Warehouse, and
# others.
#
# Before running this script:
#  - Install Python and the cx_Oracle interface
#  - Install Oracle Instant Client
#  - Download and install the cloud service wallet
#  - Modify the connect() call below to use the credentials for your database.
# See your cloud service's documentation for details.
#
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle

con = cx_Oracle.connect('username', 'password', 'connect_string')
cur = con.cursor()

# Create a table

cur.execute("""
begin
  execute immediate 'drop table mycloudtab';
  exception
  when others then
    if sqlcode not in (-00942) then
      raise;
    end if;
end;
""");

cur.execute('create table mycloudtab (id number, data varchar2(20))')

# Insert some data

rows = [ (1, "First" ), (2, "Second" ),
         (3, "Third" ), (4, "Fourth" ),
         (5, "Fifth" ), (6, "Sixth" ),
         (7, "Seventh" ) ]

cur.executemany("insert into mycloudtab(id, data) values (:1, :2)", rows)

# Query the data

cur.execute('select * from mycloudtab')
res = cur.fetchall()
print(res)
