#------------------------------------------------------------------------------
# Copyright (c) 2017, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# connection_pool.py
#   This script demonstrates the use of connection pooling in cx_Oracle. Pools
# can significantly reduce connection times for long running applications that
# repeatedly open and close connections. Internal features help protect against
# dead connections, and also aid use of Oracle Database features such as FAN
# and Application Continuity.
# The script uses threading to show multiple users of the pool. One thread
# performs a database sleep while another performs a query. A more typical
# application might be a web service that handles requests from multiple users.
# Note only one operation (such as an execute or fetch) can take place at a time
# on each connection.
#
# Also see session_callback.py.
#
#------------------------------------------------------------------------------

import threading

import cx_Oracle as oracledb
import sample_env

# Create a Connection Pool
pool = oracledb.SessionPool(user=sample_env.get_main_user(),
                            password=sample_env.get_main_password(),
                            dsn=sample_env.get_connect_string(), min=2,
                            max=5, increment=1)

def the_long_query():
    with pool.acquire() as conn:
        cursor = conn.cursor()
        cursor.arraysize = 25000
        print("the_long_query(): beginning execute...")
        cursor.execute("""
                select *
                from
                    TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers
                    cross join TestNumbers""")
        print("the_long_query(): done execute...")
        while True:
            rows = cursor.fetchmany()
            if not rows:
                break
            print("the_long_query(): fetched", len(rows), "rows...")
        print("the_long_query(): all done!")


def do_a_lock():
    with pool.acquire() as conn:
        # dbms_session.sleep() replaces dbms_lock.sleep()
        # from Oracle Database 18c
        sleep_proc_name = "dbms_session.sleep" \
                if int(conn.version.split(".")[0]) >= 18 \
                else "dbms_lock.sleep"
        cursor = conn.cursor()
        print("do_a_lock(): beginning execute...")
        cursor.callproc(sleep_proc_name, (5,))
        print("do_a_lock(): done execute...")


thread1 = threading.Thread(target=the_long_query)
thread1.start()

thread2 = threading.Thread(target=do_a_lock)
thread2.start()

thread1.join()
thread2.join()

print("All done!")
