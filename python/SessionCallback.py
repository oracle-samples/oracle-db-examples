#------------------------------------------------------------------------------
# Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# SessionCallback.py
#
# Demonstrate how to use a session callback written in Python. The callback is
# invoked whenever a newly created session is acquired from the pool, or when
# the requested tag does not match the tag that is associated with the
# session. It is generally used to set session state, so that the application
# can count on known session state, which allows the application to reduce the
# number of round trips made to the database.
#
# This script requires cx_Oracle 7.1 and higher.
#------------------------------------------------------------------------------

from __future__ import print_function

import cx_Oracle
import SampleEnv

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
def InitSession(conn, requestedTag):

    # display the requested and actual tags
    print("InitSession(): requested tag=%r, actual tag=%r" % \
            (requestedTag, conn.tag))

    # tags are expected to be in the form "key1=value1;key2=value2"
    # in this example, they are used to set NLS parameters and the tag is
    # parsed to validate it
    if requestedTag is not None:
        stateParts = []
        for directive in requestedTag.split(";"):
            parts = directive.split("=")
            if len(parts) != 2:
                raise ValueError("Tag must contain key=value pairs")
            key, value = parts
            valueDict = SUPPORTED_KEYS.get(key)
            if valueDict is None:
                raise ValueError("Tag only supports keys: %s" % \
                        (", ".join(SUPPORTED_KEYS)))
            actualValue = valueDict.get(value)
            if actualValue is None:
                raise ValueError("Key %s only supports values: %s" % \
                        (key, ", ".join(valueDict)))
            stateParts.append("%s = %s" % (key, actualValue))
        sql = "alter session set %s" % " ".join(stateParts)
        cursor = conn.cursor()
        cursor.execute(sql)

    # assign the requested tag to the connection so that when the connection
    # is closed, it will automatically be retagged; note that if the requested
    # tag is None (no tag was requested) this has no effect
    conn.tag = requestedTag


# create pool with session callback defined
pool = cx_Oracle.SessionPool(SampleEnv.GetMainUser(),
        SampleEnv.GetMainPassword(), SampleEnv.GetConnectString(), min=2,
        max=5, increment=1, threaded=True, sessionCallback=InitSession)

# acquire session without specifying a tag; since the session returned is
# newly created, the callback will be invoked but since there is no tag
# specified, no session state will be changed
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

