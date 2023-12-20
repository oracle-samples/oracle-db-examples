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
# rows_as_instance_async.py
#
# An asynchronous version of rows_as_instance.py
#
# Returns rows as instances instead of tuples. See the ceDatabase.Row class
# in the cx_PyGenLib project (http://cx-pygenlib.sourceforge.net) for a more
# advanced example.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


class Test:
    def __init__(self, a, b, c):
        self.a = a
        self.b = b
        self.c = c


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
    )

    with connection.cursor() as cursor:
        # create sample data
        await cursor.execute(
            """
            begin
                begin
                    execute immediate 'drop table TestInstances';
                exception
                when others then
                    if sqlcode <> -942 then
                        raise;
                    end if;
                end;

                execute immediate 'create table TestInstances (
                                     a varchar2(60) not null,
                                     b number(9) not null,
                                     c date not null)';

                execute immediate
                        'insert into TestInstances
                        values (''First'', 5, sysdate)';

                execute immediate
                        'insert into TestInstances
                        values (''Second'', 25, sysdate)';

                commit;
            end;
            """
        )

        # retrieve the data and display it
        await cursor.execute("select * from TestInstances")
        cursor.rowfactory = Test
        print("Rows:")
        async for row in cursor:
            print("a = %s, b = %s, c = %s" % (row.a, row.b, row.c))


asyncio.run(main())
