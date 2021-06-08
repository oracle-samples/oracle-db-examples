#------------------------------------------------------------------------------
# Copyright (c) 2019, 2021, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# session_callback.py
#
# Demonstrate how to use a connection pool session callback written in
# Python. The callback is invoked whenever a newly created session is acquired
# from the pool, or when the requested tag does not match the tag that is
# associated with the session. It is generally used to set session state, so
# that the application can count on known session state, which allows the
# application to reduce the number of round trips made to the database.
# If all your connections should have the same session state, you can simplify
# the session callback by removing the tagging logic.
#
# This script requires cx_Oracle 7.1 or higher.
#
# Also see session_callback_plsql.py
#
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

# define a dictionary of NLS_DATE_FORMAT formats supported by this sample
SUPPORTED_FORMATS = {
    "SIMPLE" : "'YYYY-MM-DD HH24:MI'",
    "FULL" : "'YYYY-MM-DD HH24:MI:SS'"
}

# define a dictionary of TIME_ZONE values supported by this sample
SUPPORTED_TIME_ZONES = {
    "UTC" : "'UTC'",
    "MST" : "'-07:00'"
}

# define a dictionary of keys that are supported by this sample
SUPPORTED_KEYS = {
    "NLS_DATE_FORMAT" : SUPPORTED_FORMATS,
    "TIME_ZONE" : SUPPORTED_TIME_ZONES
}

# define session callback
def init_session(conn, requested_tag):

    # display the requested and actual tags
    print("init_session(): requested tag=%r, actual tag=%r" % \
          (requested_tag, conn.tag))

    # tags are expected to be in the form "key1=value1;key2=value2"
    # in this example, they are used to set NLS parameters and the tag is
    # parsed to validate it
    if requested_tag is not None:
        state_parts = []
        for directive in requested_tag.split(";"):
            parts = directive.split("=")
            if len(parts) != 2:
                raise ValueError("Tag must contain key=value pairs")
            key, value = parts
            value_dict = SUPPORTED_KEYS.get(key)
            if value_dict is None:
                raise ValueError("Tag only supports keys: %s" % \
                        (", ".join(SUPPORTED_KEYS)))
            actual_value = value_dict.get(value)
            if actual_value is None:
                raise ValueError("Key %s only supports values: %s" % \
                        (key, ", ".join(value_dict)))
            state_parts.append("%s = %s" % (key, actual_value))
        sql = "alter session set %s" % " ".join(state_parts)
        cursor = conn.cursor()
        cursor.execute(sql)

    # assign the requested tag to the connection so that when the connection
    # is closed, it will automatically be retagged; note that if the requested
    # tag is None (no tag was requested) this has no effect
    conn.tag = requested_tag


# create pool with session callback defined
pool = oracledb.SessionPool(user=sample_env.get_main_user(),
                            password=sample_env.get_main_password(),
                            dsn=sample_env.get_connect_string(), min=2, max=5,
                            increment=1, session_callback=init_session)

# acquire session without specifying a tag; since the session returned is
# newly created, the callback will be invoked but since there is no tag
# specified, no session state will be changed
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
