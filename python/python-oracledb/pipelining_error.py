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
# pipelining_error.py
#
# Demonstrates warnings and errors with Oracle Database Pipelining.
# True pipelining is only available when connected to Oracle Database 23ai
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    # ------------------------------------------------------------

    print("\nExecution exception:\n")

    try:
        pipeline = oracledb.create_pipeline()
        pipeline.add_fetchall("select 1 from does_not_exist_1")
        pipeline.add_fetchall("select 2 from does_not_exist_2")

        # By default, the first failure throws an exception
        await connection.run_pipeline(pipeline)

    except oracledb.Error as e:
        (error,) = e.args
        print(error.message)

    # ------------------------------------------------------------

    print("\nContinuing after first error:\n")

    pipeline = oracledb.create_pipeline()
    pipeline.add_execute(
        """create or replace procedure myproc as
           begin
              bogus;
           end;"""
    )
    pipeline.add_fetchall("select 1 from does_not_exist_3")
    pipeline.add_fetchall("select 2 from does_not_exist_4")
    pipeline.add_fetchall("select dummy from dual")
    results = await connection.run_pipeline(pipeline, continue_on_error=True)

    for i, result in enumerate(results):
        statement = result.operation.statement
        if result.warning:
            print(
                f"Warning {result.warning.full_code} " f"in operation {i+1}:\n"
            )
            print(statement)
            print(f"{result.warning}\n")
        elif result.error:
            print(
                f"Error {result.error.full_code} "
                f"at position {result.error.offset+1} "
                f"in operation {i+1}:\n"
            )
            print(statement)
            print(f"{result.error}\n")
        elif result.rows:
            print(f"Rows from operation {i+1}:\n")
            print(statement)
            for row in result.rows:
                print(row)

    # ------------------------------------------------------------

    await connection.execute("drop procedure myproc")
    await connection.close()


asyncio.run(main())
