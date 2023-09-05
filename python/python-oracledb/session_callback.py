#------------------------------------------------------------------------------
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
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# session_callback.py
#
# Demonstrates how to use a connection pool session callback written in
# Python. The callback is invoked whenever a newly created session is acquired
# from the pool, or when the requested tag does not match the tag that is
# associated with the session. (This particular example does not show tagging)
# A callback is generally used to set session state so that the application can
# count on known session state.  This allows the application to reduce the
# number of round-trips made to the database.
#
# Also see session_callback_tagging.py and session_callback_plsql.py
#
# To run this sample:
#
#  1. Install Flask, for example like:
#
#     python -m pip install Flask
#
#  2. (Optional) Set environment variables referenced in sample_env.py
#
#  3. Run:
#
#     python session_callback.py
#
#  4. Run this script and experiment sending web requests.  For example
#     send 20 requests with a concurrency of 4:
#         ab -n 20 -c 4 http://127.0.0.1:7000/
#
#  The application console output will show that queries are executed multiple
#  times for each session created, but the initialization function for each
#  session is invoked only once.
#  ------------------------------------------------------------------------------

import os
import sys

from flask import Flask

import oracledb
import sample_env

# Port to listen on
port = int(os.environ.get('PORT', '8080'))

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

#------------------------------------------------------------------------------

# init_session(): The session callback. The requested_tag parameter is not used
# in this example.
def init_session(conn, requested_tag):
    # Your session initialization code would be here.  This example just
    # queries the session id to show that the callback is invoked once per
    # session.
    for r, in conn.cursor().execute("SELECT SYS_CONTEXT('USERENV','SID') FROM DUAL"):
        print(f"init_session() invoked for session {r}")

# start_pool(): starts the connection pool with a session callback defined
def start_pool():

    pool = oracledb.create_pool(user=sample_env.get_main_user(),
                                password=sample_env.get_main_password(),
                                dsn=sample_env.get_connect_string(),
                                min=4, max=4, increment=0,
                                session_callback=init_session)

    return pool

#------------------------------------------------------------------------------

app = Flask(__name__)

@app.route('/')
def index():
    with pool.acquire() as connection:
        with connection.cursor() as cursor:
            sql = "SELECT CURRENT_TIMESTAMP, SYS_CONTEXT('USERENV','SID') FROM DUAL"
            cursor.execute(sql)
            t,s = cursor.fetchone()
            r = f"Query at time {t} used session {s}"
            print(r)
            return r

#------------------------------------------------------------------------------

if __name__ == '__main__':

    # Start a pool of connections
    pool = start_pool()

    m = f"\nTry loading http://127.0.0.1:{port}/ in a browser\n"
    sys.modules['flask.cli'].show_server_banner = lambda *x: print(m)

    # Start a webserver
    app.run(port=port)
