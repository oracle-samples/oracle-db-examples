#------------------------------------------------------------------------------
# Copyright (c) 2016, 2023, Oracle and/or its affiliates.
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
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# generic_row_factory.py
#
# Demonstrates the ability to return named tuples for all queries using a
# subclassed cursor and row factory.
#------------------------------------------------------------------------------

import collections

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

class Connection(oracledb.Connection):

    def cursor(self):
        return Cursor(self)


class Cursor(oracledb.Cursor):

    def execute(self, statement, args=None):
        prepare_needed = (self.statement != statement)
        result = super().execute(statement, args or [])
        if prepare_needed:
            description = self.description
            if description is not None:
                names = [d.name for d in description]
                self.rowfactory = collections.namedtuple("GenericQuery", names)
        return result


# create a new subclassed connection and cursor
connection = Connection(user=sample_env.get_main_user(),
                        password=sample_env.get_main_password(),
                        dsn=sample_env.get_connect_string())

with connection.cursor() as cursor:

    # the names are now available directly for each query executed
    for row in cursor.execute("select ParentId, Description from ParentTable"):
        print(row.PARENTID, "->", row.DESCRIPTION)
    print()

    for row in cursor.execute("select ChildId, Description from ChildTable"):
        print(row.CHILDID, "->", row.DESCRIPTION)
    print()
