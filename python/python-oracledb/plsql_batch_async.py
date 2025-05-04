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
# plsql_batch_async.py
#
# An asynchronous version of plsql_batch.py
#
# Demonstrates using executemany() to make repeated calls to a PL/SQL procedure
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

    # -------------------------------------------------------------------------
    # IN and OUT PL/SQL parameter examples
    # Also shows passing in an object
    # -------------------------------------------------------------------------

    # Setup

    pipeline = oracledb.create_pipeline()

    pipeline.add_execute(
        """create or replace type my_varchar_list
               as table of varchar2(100)"""
    )

    pipeline.add_execute(
        """create or replace procedure myproc
               (p in number, names in my_varchar_list, count out number) as
           begin
               count := p + names.count;
           end;"""
    )

    await connection.run_pipeline(pipeline)

    # Example 1: positional binds

    type_obj = await connection.gettype("MY_VARCHAR_LIST")

    with connection.cursor() as cursor:

        obj1 = type_obj.newobject()
        obj1.extend(["Alex", "Bobbie"])
        obj2 = type_obj.newobject()
        obj2.extend(["Charlie", "Dave", "Eric"])
        obj3 = type_obj.newobject()
        obj3.extend(["Fred", "Georgia", "Helen", "Ian"])

        data = [
            (1, obj1),
            (2, obj2),
            (3, obj3),
        ]

        count = cursor.var(oracledb.DB_TYPE_NUMBER, arraysize=len(data))
        cursor.setinputsizes(None, type_obj, count)

        await cursor.executemany("begin myproc(:1, :2, :3); end;", data)
        print(count.values)  # [3, 5, 7]

    # Example 2: named binds

    with connection.cursor() as cursor:

        obj1 = type_obj.newobject()
        obj1.extend(["Alex", "Bobbie"])
        obj2 = type_obj.newobject()
        obj2.extend(["Charlie", "Dave", "Eric"])
        obj3 = type_obj.newobject()
        obj3.extend(["Fred", "Georgia", "Helen", "Ian"])

        data = [
            {"p": 100, "names": obj1},
            {"p": 200, "names": obj2},
            {"p": 300, "names": obj3},
        ]

        count = cursor.var(oracledb.DB_TYPE_NUMBER, arraysize=len(data))
        cursor.setinputsizes(p=None, names=type_obj, count=count)

        await cursor.executemany(
            "begin myproc(:p, :names, :count); end;", data
        )

        print(count.values)  # [102, 203, 304]

    # -------------------------------------------------------------------------
    # IN/OUT PL/SQL parameter examples
    # -------------------------------------------------------------------------

    # Setup

    pipeline = oracledb.create_pipeline()

    pipeline.add_execute(
        """create or replace procedure myproc2
              (p1 in number, p2 in out varchar2) as
           begin
               p2 := p2 || ' ' || p1;
           end;"""
    )

    await connection.run_pipeline(pipeline)

    # Example 3: positional binds

    with connection.cursor() as cursor:
        data = [(440, "Gregory"), (550, "Haley"), (660, "Ian")]
        outvals = cursor.var(
            oracledb.DB_TYPE_VARCHAR, size=100, arraysize=len(data)
        )
        cursor.setinputsizes(None, outvals)

        await cursor.executemany("begin myproc2(:1, :2); end;", data)
        print(outvals.values)  # ['Gregory 440', 'Haley 550', 'Ian 660']

    # Example 4: positional binds, utilizing setvalue()

    with connection.cursor() as cursor:
        data = [(777,), (888,), (999,)]

        inoutvals = cursor.var(
            oracledb.DB_TYPE_VARCHAR, size=100, arraysize=len(data)
        )
        inoutvals.setvalue(0, "Roger")
        inoutvals.setvalue(1, "Sally")
        inoutvals.setvalue(2, "Tom")
        cursor.setinputsizes(None, inoutvals)

        await cursor.executemany("begin myproc2(:1, :2); end;", data)
        print(inoutvals.values)  # ['Roger 777', 'Sally 888', 'Tom 999']

    # Example 5: named binds

    with connection.cursor() as cursor:
        data = [
            {"p1bv": 100, "p2bv": "Alfie"},
            {"p1bv": 200, "p2bv": "Brian"},
            {"p1bv": 300, "p2bv": "Cooper"},
        ]
        outvals = cursor.var(
            oracledb.DB_TYPE_VARCHAR, size=100, arraysize=len(data)
        )
        cursor.setinputsizes(p1bv=None, p2bv=outvals)

        await cursor.executemany("begin myproc2(:p1bv, :p2bv); end;", data)
        print(outvals.values)  # ['Alfie 100', 'Brian 200', 'Cooper 300']

    # Example 6: named binds, utilizing setvalue()

    with connection.cursor() as cursor:
        inoutvals = cursor.var(
            oracledb.DB_TYPE_VARCHAR, size=100, arraysize=len(data)
        )
        inoutvals.setvalue(0, "Dean")
        inoutvals.setvalue(1, "Elsa")
        inoutvals.setvalue(2, "Felix")
        data = [{"p1bv": 101}, {"p1bv": 202}, {"p1bv": 303}]
        cursor.setinputsizes(p1bv=None, p2bv=inoutvals)

        await cursor.executemany("begin myproc2(:p1bv, :p2bv); end;", data)
        print(inoutvals.values)  # ['Dean 101', 'Elsa 202', 'Felix 303']


asyncio.run(main())
