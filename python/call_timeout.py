#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# CallTimeout.py
#
# Demonstrate the use of the Oracle Client 18c feature that enables round trips
# to the database to time out if a specified amount of time (in milliseconds)
# has passed without a response from the database.
#
# This script requires cx_Oracle 7.0 and higher and Oracle Client 18.1 and
# higher.
#------------------------------------------------------------------------------

import cx_Oracle
import SampleEnv

connection = cx_Oracle.connect(SampleEnv.GetMainConnectString())
connection.callTimeout = 2000
print("Call timeout set at", connection.callTimeout, "milliseconds...")

cursor = connection.cursor()
cursor.execute("select sysdate from dual")
today, = cursor.fetchone()
print("Fetch of current date before timeout:", today)

# dbms_session.sleep() replaces dbms_lock.sleep() from Oracle Database 18c
sleepProcName = "dbms_session.sleep" \
        if int(connection.version.split(".")[0]) >= 18 \
        else "dbms_lock.sleep"

print("Sleeping...should time out...")
try:
    cursor.callproc(sleepProcName, (3,))
except cx_Oracle.DatabaseError as e:
    print("ERROR:", e)

cursor.execute("select sysdate from dual")
today, = cursor.fetchone()
print("Fetch of current date after timeout:", today)

