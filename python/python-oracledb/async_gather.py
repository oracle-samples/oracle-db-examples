# -----------------------------------------------------------------------------
# Copyright (c) 2023, Oracle and/or its affiliates.
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
# Multiple database sessions will be opened and used by each coroutine.  The
# number of connections opened can depend on the speed of your environment.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env

# Number of coroutines to run
CONCURRENCY = 5

# Query the unique session identifier/serial number combination of a connection
SQL = """SELECT UNIQUE CURRENT_TIMESTAMP AS CT, sid||'-'||serial# AS SIDSER
         FROM v$session_connect_info
         WHERE sid = SYS_CONTEXT('USERENV', 'SID')"""


# Show the unique session identifier/serial number of each connection that the
# pool opens
async def init_session(connection, requested_tag):
    res = await connection.fetchone(SQL)
    print(res[0].strftime("%H:%M:%S.%f"), "- init_session SID-SERIAL#", res[1])


# The coroutine simply shows the session identifier/serial number of the
# connection returned by the pool.acquire() call
async def query(pool):
    async with pool.acquire() as connection:
        await connection.callproc("dbms_session.sleep", [1])
        res = await connection.fetchone(SQL)
        print(res[0].strftime("%H:%M:%S.%f"), "- query SID-SERIAL#", res[1])


async def main():
    pool = oracledb.create_pool_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        min=1,
        max=CONCURRENCY,
        session_callback=init_session,
    )

    coroutines = [query(pool) for i in range(CONCURRENCY)]

    await asyncio.gather(*coroutines)

    await pool.close()


asyncio.run(main())
