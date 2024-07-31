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
# plsql_rowtype.py
#
# Demonstrates how to use a PL/SQL %ROWTYPE attribute
# -----------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
)

with connection.cursor() as cursor:

    cursor.execute(
        """
        begin
            begin
                execute immediate 'drop table RTSampleTable';
            exception
            when others then
                if sqlcode <> -942 then
                    raise;
                end if;
            end;

            execute immediate 'create table RTSampleTable (
                                            city varchar2(10))';

            execute immediate
                    'insert into RTSampleTable values (''London'')';

            commit;

        end;
        """
    )

    cursor.execute(
        """
        create or replace function TestFuncOUT return RTSampleTable%rowtype as
            r RTSampleTable%rowtype;
        begin
            select * into r from RTSampleTable where rownum < 2 order by 1;
            return r;
        end;"""
    )
    if cursor.warning:
        print(cursor.warning)

    cursor.execute(
        """
        create or replace procedure TestProcIN(
            r in RTSampleTable%rowtype, city out varchar2) as
        begin
            city := r.city;
        end;"""
    )
    if cursor.warning:
        print(cursor.warning)

    # Getting a %ROWTYPE from PL/SQL returns a python-oracledb DbObject record

    rt = connection.gettype("RTSAMPLETABLE%ROWTYPE")
    r = cursor.callfunc("TESTFUNCOUT", rt)
    print("1. City is:", r.CITY)
    # dump_object(r)           # This is defined in object_dump.py

    # An equivalent record can be directly constructed

    obj = rt.newobject()
    obj.CITY = "My Town"

    # Passing a record to a %ROWTYPE parameter

    c = cursor.var(oracledb.DB_TYPE_VARCHAR)
    cursor.callproc("TESTPROCIN", [r, c])
    print("2. City is:", c.getvalue())

    cursor.callproc("TESTPROCIN", [obj, c])
    print("3. City is:", c.getvalue())
