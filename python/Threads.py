#------------------------------------------------------------------------------
# Copyright 2017, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# Threads.py
#   This script demonstrates the use of threads with cx_Oracle. A session pool
# is used so that multiple connections are available to perform work on the
# database. Only one operation (such as an execute or fetch) can take place at
# a time on a connection. In the below example, one of the threads performs
# dbms_lock.sleep while the other performs a query.
#
# This script requires cx_Oracle 2.5 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import threading

pool = cx_Oracle.SessionPool("cx_Oracle", "dev", "localhost/orcl", 2, 5, 1,
        threaded = True)

def TheLongQuery():
    conn = pool.acquire()
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
    conn = pool.acquire()
    cursor = conn.cursor()
    print("DoALock(): beginning execute...")
    cursor.callproc("dbms_lock.sleep", (5,))
    print("DoALock(): done execute...")


thread1 = threading.Thread(None, TheLongQuery)
thread1.start()

thread2 = threading.Thread(None, DoALock)
thread2.start()

thread1.join()
thread2.join()

print("All done!")

