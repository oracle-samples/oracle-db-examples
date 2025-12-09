# -----------------------------------------------------------------------------
# Copyright (c) 2022, 2025, Oracle and/or its affiliates.
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
# connection_pool.py
#
# Demonstrates the use of connection pooling using a Flask web application.
#
# This also shows the use of pool_alias for connection pool caching, so the
# pool handle does not need to passed through the app.
#
# Connection Pools can significantly reduce connection times for long running
# applications that repeatedly open and close connections.  Connection pools
# allow multiple, concurrent web requests to be efficiently handled.  Internal
# features help protect against dead connections, and also aid use of Oracle
# Database features such as FAN and Application Continuity.
#
# To run this sample:
#
#  1. Install Flask, for example like:
#
#     python -m pip install flask
#
#  2. (Optional) Set environment variables referenced in sample_env.py
#
#  3. Run:
#
#     python connection_pool.py
#
#  4. In a browser load a URL as shown below.
#
# The default route will display a welcome message:
#   http://127.0.0.1:8080/
#
# To find a username you can pass an id, for example 1:
#   http://127.0.0.1:8080/user/1
#
# To insert new a user 'fred' you can call:
#   http://127.0.0.1:8080/post/fred
#
# -----------------------------------------------------------------------------

import os
import sys

from flask import Flask

import oracledb
import sample_env

# Port to listen on
PORT = int(os.environ.get("PORT", "8080"))

# Generally a fixed-size pool is recommended, i.e. POOL_MIN=POOL_MAX.  Here
# the pool contains 4 connections, which will allow 4 concurrent users.
POOL_MIN = 4
POOL_MAX = 4
POOL_INC = 0

# Pool name for the connection pool cache
POOL_ALIAS_NAME = "mypool"

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())


# -----------------------------------------------------------------------------


# start_pool(): starts the connection pool
#
# The pool is stored in the pool cache. Connections can later be acquired from
# the pool by passing the same pool_alias value to oracledb.connect()
def start_pool():
    oracledb.create_pool(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_pool_params(),
        min=POOL_MIN,
        max=POOL_MAX,
        increment=POOL_INC,
        session_callback=init_session,
        pool_alias=POOL_ALIAS_NAME,
    )


# init_session(): a 'session callback' to efficiently set any initial state
# that each connection should have.
#
# This particular demo doesn't use dates, so sessionCallback could be omitted,
# but it does show the kinds of settings many apps would use.
#
# If you have multiple SQL statements, an optimization is to call them all in a
# PL/SQL anonymous block with BEGIN/END so you only use cursor.execute() once.
# This is shown later in create_schema().
#
def init_session(connection, requestedTag_ignored):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            alter session set
                time_zone = 'UTC'
                nls_date_format = 'YYYY-MM-DD HH24:MI'
            """
        )


# -----------------------------------------------------------------------------


# create_schema(): drop and create the demo table, and add a row
def create_schema():
    with oracledb.connect(pool_alias=POOL_ALIAS_NAME) as connection:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                begin
                    begin
                        execute immediate 'drop table demo';
                    exception when others then
                        if sqlcode <> -942 then
                            raise;
                        end if;
                    end;

                    execute immediate 'create table demo (
                        id       number generated by default as identity,
                        username varchar2(40)
                    )';

                    execute immediate 'insert into demo (username) values
                        (''chris'')';

                    commit;
                end;
                """
            )


# -----------------------------------------------------------------------------

app = Flask(__name__)


# Display a welcome message on the 'home' page
@app.route("/")
def index():
    return "Welcome to the demo app"


# Add a new username
#
# The new user's id is generated by the database and returned in the OUT bind
# variable 'idbv'.
@app.route("/post/<string:username>")
def post(username):
    with oracledb.connect(pool_alias=POOL_ALIAS_NAME) as connection:
        with connection.cursor() as cursor:
            connection.autocommit = True
            idbv = cursor.var(int)
            cursor.execute(
                """
                insert into demo (username)
                values (:unbv)
                returning id into :idbv
                """,
                [username, idbv],
            )
            return f"Inserted {username} with id {idbv.getvalue()[0]}"


# Show the username for a given id
@app.route("/user/<int:id>")
def show_username(id):
    with oracledb.connect(pool_alias=POOL_ALIAS_NAME) as connection:
        with connection.cursor() as cursor:
            cursor.execute("select username from demo where id = :idbv", [id])
            r = cursor.fetchone()
            return r[0] if r is not None else "Unknown user id"


# -----------------------------------------------------------------------------

if __name__ == "__main__":
    # Start a pool of connections
    start_pool()

    # Create a demo table
    create_schema()

    m = f"\nTry loading http://127.0.0.1:{PORT}/user/1 in a browser\n"
    sys.modules["flask.cli"].show_server_banner = lambda *x: print(m)

    # Start a webserver
    app.run(port=PORT)
