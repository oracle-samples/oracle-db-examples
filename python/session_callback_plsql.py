#------------------------------------------------------------------------------
# Copyright (c) 2019, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# session_callback_plsql.py
#
# Demonstrate how to use a connection pool session callback written in
# PL/SQL. The callback is invoked whenever the tag requested by the application
# does not match the tag associated with the session in the pool. It should be
# used to set session state, so that the application can count on known session
# state, which allows the application to reduce the number of round trips to the
# database.
#
# The primary advantage to this approach over the equivalent approach shown in
# session_callback.py is when DRCP is used, as the callback is invoked on the
# server and no round trip is required to set state.
#
# This script requires cx_Oracle 7.1 or higher.
#
# Also see session_callback.py
#
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

# create pool with session callback defined
pool = oracledb.SessionPool(user=sample_env.get_main_user(),
                            password=sample_env.get_main_password(),
                            dsn=sample_env.get_connect_string(), min=2, max=5,
                            increment=1, session_callback="pkg_SessionCallback.TheCallback")

# truncate table logging calls to PL/SQL session callback
with pool.acquire() as conn:
    cursor = conn.cursor()
    cursor.execute("truncate table PLSQLSessionCallbacks")

# acquire session without specifying a tag; the callback will not be invoked as
# a result and no session state will be changed
print("(1) acquire session without tag")
with pool.acquire() as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    result, = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying a tag; since the session returned has no tag,
# the callback will be invoked; session state will be changed and the tag will
# be saved when the connection is closed
print("(2) acquire session with tag")
with pool.acquire(tag="NLS_DATE_FORMAT=SIMPLE") as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    result, = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying the same tag; since a session exists in the pool
# with this tag, it will be returned and the callback will not be invoked but
# the connection will still have the session state defined previously
print("(3) acquire session with same tag")
with pool.acquire(tag="NLS_DATE_FORMAT=SIMPLE") as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    result, = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying a different tag; since no session exists in the
# pool with this tag, a new session will be returned and the callback will be
# invoked; session state will be changed and the tag will be saved when the
# connection is closed
print("(4) acquire session with different tag")
with pool.acquire(tag="NLS_DATE_FORMAT=FULL;TIME_ZONE=UTC") as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    result, = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying a different tag but also specifying that a
# session with any tag can be acquired from the pool; a session with one of the
# previously set tags will be returned and the callback will be invoked;
# session state will be changed and the tag will be saved when the connection
# is closed
print("(4) acquire session with different tag but match any also specified")
with pool.acquire(tag="NLS_DATE_FORMAT=FULL;TIME_ZONE=MST", matchanytag=True) \
        as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    result, = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session and display results from PL/SQL session logs
with pool.acquire() as conn:
    cursor = conn.cursor()
    cursor.execute("""
            select RequestedTag, ActualTag
            from PLSQLSessionCallbacks
            order by FixupTimestamp""")
    print("(5) PL/SQL session callbacks")
    for requestedTag, actualTag in cursor:
        print("Requested:", requestedTag, "Actual:", actualTag)
