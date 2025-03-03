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
# pipelining_basic.py
#
# Demonstrates Oracle Database Pipelining.
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

    # Create a pipeline and define the operations
    pipeline = oracledb.create_pipeline()

    pipeline.add_fetchone("select user from dual")

    pipeline.add_fetchone("select sysdate from dual")

    rows = [
        (1, "First"),
        (2, "Second"),
        (3, "Third"),
        (4, "Fourth"),
        (5, "Fifth"),
        (6, "Sixth"),
    ]
    pipeline.add_executemany(
        "insert into mytab(id, data) values (:1, :2)", rows
    )

    # pipeline.add_commit()  # uncomment to persist data

    pipeline.add_execute(
        """create or replace procedure myprocerr as
           begin
              bogus;
           end;"""
    )

    pipeline.add_execute(
        """create or replace procedure myproc2 (p in number) as
           begin
              null;
           end;"""
    )

    pipeline.add_execute(
        """create or replace function myfunc (p in number) return number as
           begin
              return p;
           end;"""
    )

    pipeline.add_callproc("myproc2", [123])

    pipeline.add_callfunc("myfunc", oracledb.DB_TYPE_NUMBER, [456])

    pipeline.add_fetchall("select 3 from does_not_exist")

    pipeline.add_fetchall("select * from mytab")

    # Run the operations in the pipeline.
    # Note although the database receives all the operations at the same time,
    # it will execute each operation sequentially
    results = await connection.run_pipeline(pipeline, continue_on_error=True)

    # Print the query results
    for i, result in enumerate(results):
        statement = result.operation.statement
        op_type = result.operation.op_type

        if result.warning:
            print(f"\n-> OPERATION {i+1}: WARNING\n")
            print(statement)
            print(f"{result.warning}\n")

        elif result.error:
            # This will only be invoked if the pipeline is run with
            # continue_on_error=True
            offset = result.error.offset
            print(f"\n-> OPERATION {i+1}: ERROR AT POSITION {offset}:\n")
            print(statement, "\n")
            print(f"{result.error}\n")

        elif op_type == oracledb.PipelineOpType.EXECUTE:
            print(f"\n-> OPERATION {i+1}: EXECUTE\n")
            print(statement)

        elif op_type == oracledb.PipelineOpType.EXECUTE_MANY:
            print(f"\n-> OPERATION {i+1}: EXECUTE_MANY\n")
            print(statement)

        elif result.rows:
            print(f"\n-> OPERATION {i+1}: ROWS\n")
            print(statement, "\n")
            headings = [col.name for col in result.columns]
            print(*headings, sep="\t")
            print("--")
            for row in result.rows:
                print(*row, sep="\t")

        elif op_type == oracledb.PipelineOpType.CALL_PROC:
            print(f"\n-> OPERATION {i+1}: CALL_PROC\n")
            print(result.operation.name)

        elif op_type == oracledb.PipelineOpType.CALL_FUNC:
            print(f"\n-> OPERATION {i+1}: CALL_FUNC\n")
            print(result.operation.name)
            print(result.return_value)

        elif op_type == oracledb.PipelineOpType.COMMIT:
            print(f"\n-> OPERATION {i+1}: COMMIT")

        else:
            print(f"\n-> OPERATION {i+1}: Unknown\n")
            print(f"Operation type: {op_type}")

    # ------------------------------------------------------------

    await connection.close()


asyncio.run(main())
