# -----------------------------------------------------------------------------
# Copyright (c) 2022, 2024, Oracle and/or its affiliates.
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
# drcp_pool.py
#
# Demonstrates the use of Database Resident Connection Pooling (DRCP)
# connection pooling using a Flask web application.  This sample is similar to
# connection_pool.py
#
# DRCP can be used with standalone connections from connect(), but it is often
# used together with a python-oracledb connection pool created with
# create_pool(), as shown here.
#
# DRCP provides a connection pool in the database server. The pool reduces the
# cost of creating and tearing down database server processs.  This pool of
# server processes can be shared across application processs, allowing for
# resource sharing.
#
# There is no difference in how a connection is used once it has been
# established.
#
# To use DRCP, the connection string should request the database use a pooled
# server.  For example, "localhost/orclpdb:pooled".  It is best practice for
# connections to specify a connection class and server purity when creating
# a pool
#
# For on premise databases, the DRCP pool can be started and stopped in the
# database by issuing the following commands in SQL*Plus:
#
#   exec dbms_connection_pool.start_pool()
#   exec dbms_connection_pool.stop_pool()
#
# For multitenant databases, DRCP management needs to be done the root ("CDB")
# database unless the database initialization parameter ENABLE_PER_PDB_DRCP is
# TRUE.
#
# Oracle Autonomous Databases already have DRCP enabled.
#
# Statistics on DRCP usage are recorded in various data dictionary views, for
# example in V$CPOOL_CC_STATS.
#
# See the python-oracledb documentation for more information on DRCP.
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
#     python drcp_pool.py
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
# Multi-user load can be simulated with a testing tool such as 'ab':
#
#   ab -n 1000 -c 4 http://127.0.0.1:8080/user/1
#
# Then you can query the data dictionary:
#
#   select cclass_name, num_requests, num_hits,
#          num_misses, num_waits, num_authentications as num_auths
#   from   v$cpool_cc_stats;
#
# Output will be like:
#
#   CCLASS_NAME      NUM_REQUESTS NUM_HITS NUM_MISSES NUM_WAITS NUM_AUTHS
#   ---------------- ------------ -------- ---------- --------- ---------
#   PYTHONDEMO.MYAPP         1001      997          4         0         4
#
# With ADB-S databases, query V$CPOOL_CONN_INFO instead.
#
# -----------------------------------------------------------------------------

import os
import sys

from flask import Flask

import oracledb
import sample_env

# Port to listen on
port = int(os.environ.get("PORT", "8080"))

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# -----------------------------------------------------------------------------


# start_pool(): starts the connection pool
def start_pool():
    # Generally a fixed-size pool is recommended, i.e. pool_min=pool_max.  Here
    # the pool contains 4 connections, which will allow 4 concurrent users.

    pool_min = 4
    pool_max = 4
    pool_inc = 0

    pool = oracledb.create_pool(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_drcp_connect_string(),
        params=sample_env.get_pool_params(),
        min=pool_min,
        max=pool_max,
        increment=pool_inc,
        session_callback=init_session,
        cclass="MYAPP",
        purity=oracledb.ATTR_PURITY_SELF,
    )

    return pool


# init_session(): a 'session callback' to efficiently set any initial state
# that each connection should have.
#
# This particular demo doesn't use dates, so sessionCallback could be omitted,
# but it does show the kinds of settings many apps would use.
#
# If you have multiple SQL statements, then call them all in a PL/SQL anonymous
# block with BEGIN/END so you only use execute() once.  This is shown later in
# create_schema().
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
    with pool.acquire() as connection:
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

                    execute immediate 'insert into demo (username)
                    values (''chris'')';

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
    with pool.acquire() as connection:
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
    with pool.acquire() as connection:
        with connection.cursor() as cursor:
            cursor.execute("select username from demo where id = :idbv", [id])
            r = cursor.fetchone()
            return r[0] if r is not None else "Unknown user id"


# -----------------------------------------------------------------------------

if __name__ == "__main__":
    # Start a pool of connections
    pool = start_pool()

    # Create a demo table
    create_schema()

    m = f"\nTry loading http://127.0.0.1:{port}/user/1 in a browser\n"
    sys.modules["flask.cli"].show_server_banner = lambda *x: print(m)

    # Start a webserver
    app.run(port=port)
