# -----------------------------------------------------------------------------
# Copyright (c) 2016, 2024, Oracle and/or its affiliates.
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
# subclassing.py
#
# Demonstrates how to subclass connections and cursors in order to add
# additional functionality (like logging) or create specialized interfaces for
# particular applications.
# -----------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())


# sample subclassed Connection which overrides the constructor (so no
# parameters are required) and the cursor() method (so that the subclassed
# cursor is returned instead of the default cursor implementation)
class Connection(oracledb.Connection):
    def __init__(self):
        print("CONNECT", sample_env.get_connect_string())
        super().__init__(
            user=sample_env.get_main_user(),
            password=sample_env.get_main_password(),
            dsn=sample_env.get_connect_string(),
            params=sample_env.get_connect_params(),
        )

    def cursor(self):
        return Cursor(self)


# sample subclassed cursor which overrides the execute() and fetchone()
# methods in order to perform some simple logging
class Cursor(oracledb.Cursor):
    def execute(self, statement, args):
        print("EXECUTE", statement)
        print("ARGS:")
        for arg_index, arg in enumerate(args):
            print("   ", arg_index + 1, "=>", repr(arg))
        return super().execute(statement, args)

    def fetchone(self):
        print("FETCHONE")
        return super().fetchone()


# create instances of the subclassed Connection and cursor
connection = Connection()

with connection.cursor() as cursor:
    # demonstrate that the subclassed connection and cursor are being used
    cursor.execute(
        "select count(*) from ChildTable where ParentId = :1", (30,)
    )
    (count,) = cursor.fetchone()
    print("COUNT:", int(count))
