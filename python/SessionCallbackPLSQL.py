#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# SessionCallbackPLSQL.py
#
# Demonstrate how to use a session callback written in PL/SQL. The callback is
# invoked whenever the tag requested by the application does not match the tag
# associated with the session in the pool. It should be used to set session
# state, so that the application can count on known session state, which allows
# the application to reduce the number of round trips to the database.
#
# The primary advantage to this approach over the equivalent approach shown in
# SessionCallback.py is when DRCP is used, as the callback is invoked on the
# server and no round trip is required to set state.
#
# This script requires cx_Oracle 7.1 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

# create pool with session callback defined
pool = cx_Oracle.SessionPool(SampleEnv.GetMainUser(),
        SampleEnv.GetMainPassword(), SampleEnv.GetConnectString(), min=2,
        max=5, increment=1, threaded=True,
        sessionCallback="pkg_SessionCallback.TheCallback")

# truncate table logging calls to PL/SQL session callback
conn = pool.acquire()
cursor = conn.cursor()
cursor.execute("truncate table PLSQLSessionCallbacks")
conn.close()

# acquire session without specifying a tag; the callback will not be invoked as
# a result and no session state will be changed
print("(1) acquire session without tag")
conn = pool.acquire()
cursor = conn.cursor()
cursor.execute("select to_char(current_date) from dual")
result, = cursor.fetchone()
print("main(): result is", repr(result))
conn.close()

# acquire session, specifying a tag; since the session returned has no tag,
# the callback will be invoked; session state will be changed and the tag will
# be saved when the connection is closed
print("(2) acquire session with tag")
conn = pool.acquire(tag="NLS_DATE_FORMAT=SIMPLE")
cursor = conn.cursor()
cursor.execute("select to_char(current_date) from dual")
result, = cursor.fetchone()
print("main(): result is", repr(result))
conn.close()

# acquire session, specifying the same tag; since a session exists in the pool
# with this tag, it will be returned and the callback will not be invoked but
# the connection will still have the session state defined previously
print("(3) acquire session with same tag")
conn = pool.acquire(tag="NLS_DATE_FORMAT=SIMPLE")
cursor = conn.cursor()
cursor.execute("select to_char(current_date) from dual")
result, = cursor.fetchone()
print("main(): result is", repr(result))
conn.close()

# acquire session, specifying a different tag; since no session exists in the
# pool with this tag, a new session will be returned and the callback will be
# invoked; session state will be changed and the tag will be saved when the
# connection is closed
print("(4) acquire session with different tag")
conn = pool.acquire(tag="NLS_DATE_FORMAT=FULL;TIME_ZONE=UTC")
cursor = conn.cursor()
cursor.execute("select to_char(current_date) from dual")
result, = cursor.fetchone()
print("main(): result is", repr(result))
conn.close()

# acquire session, specifying a different tag but also specifying that a
# session with any tag can be acquired from the pool; a session with one of the
# previously set tags will be returned and the callback will be invoked;
# session state will be changed and the tag will be saved when the connection
# is closed
print("(4) acquire session with different tag but match any also specified")
conn = pool.acquire(tag="NLS_DATE_FORMAT=FULL;TIME_ZONE=MST", matchanytag=True)
cursor = conn.cursor()
cursor.execute("select to_char(current_date) from dual")
result, = cursor.fetchone()
print("main(): result is", repr(result))
conn.close()

# acquire session and display results from PL/SQL session logs
conn = pool.acquire()
cursor = conn.cursor()
cursor.execute("""
        select RequestedTag, ActualTag
        from PLSQLSessionCallbacks
        order by FixupTimestamp""")
print("(5) PL/SQL session callbacks")
for requestedTag, actualTag in cursor:
    print("Requested:", requestedTag, "Actual:", actualTag)

