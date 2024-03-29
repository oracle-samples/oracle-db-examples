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
# plsql_collection_async.py
#
# An asynchronous version of plsql_collection.py
#
# Demonstrates how to get the value of a PL/SQL collection from a stored
# procedure.
#
# This feature is only available in Oracle Database 12.1 and higher.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
    )

    # create a new empty object of the correct type.
    # note the use of a PL/SQL type that is defined in a package
    type_obj = await connection.gettype("PKG_DEMO.UDT_STRINGLIST")
    obj = type_obj.newobject()

    # call the stored procedure which will populate the object
    with connection.cursor() as cursor:
        await cursor.callproc("pkg_Demo.DemoCollectionOut", (obj,))

        # show the indexes that are used by the collection
        print("Indexes and values of collection:")
        ix = obj.first()
        while ix is not None:
            print(ix, "->", obj.getelement(ix))
            ix = obj.next(ix)
        print()

        # show the values as a simple list
        print("Values of collection as list:")
        print(obj.aslist())
        print()

        # show the values as a simple dictionary
        print("Values of collection as dictionary:")
        print(obj.asdict())
        print()


asyncio.run(main())
