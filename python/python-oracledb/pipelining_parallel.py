# -----------------------------------------------------------------------------
# Copyright (c) 2024, Oracle and/or its affiliates.
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
# pipelining_parallel.py
#
# Demonstrates Oracle Database Pipelining running local and database operations
# concurrently.
# True pipelining is only available when connected to Oracle Database 23ai
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


async def run_thing_one():
    return "thing_one"


async def run_thing_two():
    return "thing_two"


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    pipeline = oracledb.create_pipeline()
    pipeline.add_fetchone("select user from dual")
    pipeline.add_fetchone("select sysdate from dual")

    # Run the pipeline and non-database operations concurrently.
    # Note although the database receives all the operations at the same time,
    # it will execute each operation sequentially. It is the local and
    # database tasks that execute concurrently.
    return_values = await asyncio.gather(
        run_thing_one(), run_thing_two(), connection.run_pipeline(pipeline)
    )

    for r in return_values:
        if isinstance(r, list):  # the pipeline return list
            for result in r:
                if result.rows:
                    for row in result.rows:
                        print(*row, sep="\t")
        else:
            print(r)  # a local operation result

    await connection.close()


asyncio.run(main())
