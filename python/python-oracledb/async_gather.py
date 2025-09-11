# -----------------------------------------------------------------------------
# Copyright (c) 2023, 2025, Oracle and/or its affiliates.
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
# async_gather.py
#
# Demonstrates using a connection pool with asyncio and gather().
#
# This also shows the use of pool_alias for connection pool caching, so the
# pool handle does not need to passed through the app.
#
# Each coroutine invocation will acquire a connection from the connection pool.
# The number of connections in the pool will depend on the speed of your
# environment. In some cases existing connections will get reused. In other
# cases up to CONCURRENCY connections will be created by the pool.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env

# Pool name for the connection pool cache
POOL_ALIAS_NAME = "mypool"

# Number of coroutines to run
CONCURRENCY = 5

# Query the unique session identifier/serial number combination of a connection
SQL = """select unique current_timestamp as ct, sid||'-'||serial# as sidser
         from v$session_connect_info
         where sid = sys_context('userenv', 'sid')"""


# Show the unique session identifier/serial number of each connection that the
# pool creates
async def init_session(connection, requested_tag):
    res = await connection.fetchone(SQL)
    print(res[0].strftime("%H:%M:%S.%f"), "- init_session SID-SERIAL#", res[1])


# The coroutine simply shows the session identifier/serial number of the
# connection returned from the pool
async def query():
    async with oracledb.connect_async(
        pool_alias=POOL_ALIAS_NAME
    ) as connection:
        await connection.callproc("dbms_session.sleep", [1])
        res = await connection.fetchone(SQL)
        print(res[0].strftime("%H:%M:%S.%f"), "- query SID-SERIAL#", res[1])


async def main():
    oracledb.create_pool_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_pool_params(),
        min=1,
        max=CONCURRENCY,
        session_callback=init_session,
        pool_alias=POOL_ALIAS_NAME,
    )

    coroutines = [query() for i in range(CONCURRENCY)]

    await asyncio.gather(*coroutines)

    pool = oracledb.get_pool(POOL_ALIAS_NAME)
    await pool.close()


asyncio.run(main())
