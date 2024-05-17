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
# insert_geometry_async.py
#
# An asynchronous version of insert_geometry.py
#
# Demonstrates the ability to create Oracle objects (this example uses
# SDO_GEOMETRY) and insert them into a table.
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

    # create and populate Oracle objects
    type_obj = await connection.gettype("MDSYS.SDO_GEOMETRY")
    element_info_type_obj = await connection.gettype(
        "MDSYS.SDO_ELEM_INFO_ARRAY"
    )
    ordinate_type_obj = await connection.gettype("MDSYS.SDO_ORDINATE_ARRAY")
    obj = type_obj.newobject()
    obj.SDO_GTYPE = 2003
    obj.SDO_ELEM_INFO = element_info_type_obj.newobject()
    obj.SDO_ELEM_INFO.extend([1, 1003, 3])
    obj.SDO_ORDINATES = ordinate_type_obj.newobject()
    obj.SDO_ORDINATES.extend([1, 1, 5, 7])
    print("Created object", obj)

    with connection.cursor() as cursor:
        await cursor.execute("truncate table TestGeometry")
        print("Adding row to table...")
        await cursor.execute(
            "insert into TestGeometry values (1, :objbv)", objbv=obj
        )
        await connection.commit()
        print("Success!")


asyncio.run(main())
