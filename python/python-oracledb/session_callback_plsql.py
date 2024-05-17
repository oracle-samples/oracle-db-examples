# -----------------------------------------------------------------------------
# Copyright (c) 2019, 2023, Oracle and/or its affiliates.
#
# This software is dual-licensed to you under the Universal Permissive License
# (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl and Apache License
# 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
# either license.
#
# If you elect to accept the software under the Apache License, Version 2.0,
# the following applies:
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# session_callback_plsql.py
#
# Demonstrates how to use a connection pool session callback written in
# PL/SQL. The callback is invoked whenever the tag requested by the application
# does not match the tag associated with the session in the pool. It should be
# used to set session state so that the application can count on known session
# state. This allows the application to reduce the number of round-trips to the
# database.
#
# The primary advantage to this approach over the equivalent approach shown in
# session_callback.py and session_callback_tagging.py is when DRCP is used, as
# the callback is invoked on the server and no round trip is required to set
# state.
#
# Also see session_callback.py and session_callback_tagging.py
# -----------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# create pool with session callback defined
pool = oracledb.create_pool(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    min=2,
    max=5,
    increment=1,
    session_callback="pkg_SessionCallback.TheCallback",
)

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
    (result,) = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying a tag; since the session returned has no tag,
# the callback will be invoked; session state will be changed and the tag will
# be saved when the connection is closed
print("(2) acquire session with tag")
with pool.acquire(tag="NLS_DATE_FORMAT=SIMPLE") as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    (result,) = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying the same tag; since a session exists in the pool
# with this tag, it will be returned and the callback will not be invoked but
# the connection will still have the session state defined previously
print("(3) acquire session with same tag")
with pool.acquire(tag="NLS_DATE_FORMAT=SIMPLE") as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    (result,) = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying a different tag; since no session exists in the
# pool with this tag, a new session will be returned and the callback will be
# invoked; session state will be changed and the tag will be saved when the
# connection is closed
print("(4) acquire session with different tag")
with pool.acquire(tag="NLS_DATE_FORMAT=FULL;TIME_ZONE=UTC") as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    (result,) = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session, specifying a different tag but also specifying that a
# session with any tag can be acquired from the pool; a session with one of the
# previously set tags will be returned and the callback will be invoked;
# session state will be changed and the tag will be saved when the connection
# is closed
print("(4) acquire session with different tag but match any also specified")
with pool.acquire(
    tag="NLS_DATE_FORMAT=FULL;TIME_ZONE=MST", matchanytag=True
) as conn:
    cursor = conn.cursor()
    cursor.execute("select to_char(current_date) from dual")
    (result,) = cursor.fetchone()
    print("main(): result is", repr(result))

# acquire session and display results from PL/SQL session logs
with pool.acquire() as conn:
    cursor = conn.cursor()
    cursor.execute(
        """
        select RequestedTag, ActualTag
        from PLSQLSessionCallbacks
        order by FixupTimestamp
        """
    )
    print("(5) PL/SQL session callbacks")
    for requestedTag, actualTag in cursor:
        print("Requested:", requestedTag, "Actual:", actualTag)
