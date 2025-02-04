# -----------------------------------------------------------------------------
# Copyright (c) 2023, 2024, Oracle and/or its affiliates.
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
# dbms_output_async.py
#
# An asynchronous version of dbms_output.py
#
# Demonstrates one method of fetching the lines produced by the DBMS_OUTPUT
# package.
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

    with connection.cursor() as cursor:
        # enable DBMS_OUTPUT
        await cursor.callproc("dbms_output.enable")

        # execute some PL/SQL that generates output with DBMS_OUTPUT.PUT_LINE
        await cursor.execute(
            """
            begin
                dbms_output.put_line('This is some text');
                dbms_output.put_line('');
                dbms_output.put_line('Demonstrating use of DBMS_OUTPUT');
            end;
            """
        )

        # tune this size for your application
        chunk_size = 10

        # create variables to hold the output
        lines_var = cursor.arrayvar(str, chunk_size)
        num_lines_var = cursor.var(int)
        num_lines_var.setvalue(0, chunk_size)

        # fetch the text that was added by PL/SQL
        while True:
            await cursor.callproc(
                "dbms_output.get_lines", (lines_var, num_lines_var)
            )
            num_lines = num_lines_var.getvalue()
            lines = lines_var.getvalue()[:num_lines]
            for line in lines:
                print(line or "")
            if num_lines < chunk_size:
                break


asyncio.run(main())
