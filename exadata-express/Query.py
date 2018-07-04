#------------------------------------------------------------------------------
# Query.py
#
# Demonstrate how to perform a query of a database schema, configured with Oracle's sample HR Schema, in your Exadata Express
# Cloud Service.
#
# Before running this app:
#   1. From the Exadata Express Cloud Service Console, click on Develop, then click on Python. Follow displayed instructions to: 
#      - Install instant client.
#      - Enable client access and download your Exadata Express Cloud Service credentials.
#      - Install the Python Extension module (cx_Oracle) to enable access to your cloud service.
#   2. Create a schema using the Exadata Express Cloud Service Console. Remember the schema name and password for step 4.
#   3. Configure the schema with Oracle's Sample HR Schema. Scripts to configure this schema can be found on GitHub. 
#      See github.com/oracle/db-sample-schemas for scripts and instructions.
#   4. Modify cx_Oracle.connect to connect to the HR schema you created in step 2: 
#      - The first value is the name of your HR schema.
#      - The second value is the password for your HR schema.
#      - The third value is "dbaccess", which is defined in the wallet downloaded from the Exadata Express Cloud Service 
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle


connection = cx_Oracle.connect('HR',password,'dbaccess')

sql = """
select * from employees where department_id = 90"""
        

print("Get all rows via iterator")
cursor = connection.cursor()
for result in cursor.execute(sql):
    print(result)
print()

