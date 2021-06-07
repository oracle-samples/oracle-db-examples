#------------------------------------------------------------------------------
# Copyright (c) 2017, 2020, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# ConnectionPool.py
#   This script demonstrates the use of connection pooling in cx_Oracle. Pools
# can significantly reduce connection times for long running applications that
# repeatedly open and close connections. Internal features help protect against
# dead connections, and also aid use of Oracle Database features such as FAN
# and Application Continuity.
# The script uses threading to show multiple users of the pool. One thread
# performs a database sleep while another performs a query. A more typical
# application might be a web service that handles requests from multiple users.
# Applications that use connections concurrently in multiple threads should set
# the 'threaded' parameter to True. Note only one operation (such as an execute
# or fetch) can take place at a time on each connection.
#
# Also see SessionCallback.py.
#
#------------------------------------------------------------------------------

import cx_Oracle
import SampleEnv
import threading

# Create a Connection Pool
pool = cx_Oracle.SessionPool(SampleEnv.GetMainUser(),
        SampleEnv.GetMainPassword(), SampleEnv.GetConnectString(), min=2,
        max=5, increment=1, threaded=True)

# dbms_session.sleep() replaces dbms_lock.sleep() from Oracle Database 18c
with pool.acquire() as conn:
    sleepProcName = "dbms_session.sleep" \
            if int(conn.version.split(".")[0]) >= 18 \
            else "dbms_lock.sleep"

def TheLongQuery():
    with pool.acquire() as conn:
        cursor = conn.cursor()
        cursor.arraysize = 25000
        print("TheLongQuery(): beginning execute...")
        cursor.execute("""
                select *
                from
                    TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers""")
        print("TheLongQuery(): done execute...")
        while True:
            rows = cursor.fetchmany()
            if not rows:
                break
            print("TheLongQuery(): fetched", len(rows), "rows...")
        print("TheLongQuery(): all done!")


def DoALock():
    with pool.acquire() as conn:
        cursor = conn.cursor()
        print("DoALock(): beginning execute...")
        cursor.callproc(sleepProcName, (5,))
        print("DoALock(): done execute...")


thread1 = threading.Thread(None, TheLongQuery)
thread1.start()

thread2 = threading.Thread(None, DoALock)
thread2.start()

thread1.join()
thread2.join()

print("All done!")
