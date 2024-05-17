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
# object_dump_async.py
#
# An asynchronous version of object_dump.py
#
# Shows how to pretty-print an Oracle object or collection.
# Also shows how to insert a Python object to an Oracle object column.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


async def main():
    # Create Oracle connection and cursor objects
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
    )
    cursor = connection.cursor()

    # Create a Python class equivalent to an Oracle SDO object
    class MySDO(object):
        def __init__(self, gtype, elem_info, ordinates):
            self.gtype = gtype
            self.elem_info = elem_info
            self.ordinates = ordinates

    # Get Oracle type information
    obj_type = await connection.gettype("MDSYS.SDO_GEOMETRY")
    element_info_type_obj = await connection.gettype(
        "MDSYS.SDO_ELEM_INFO_ARRAY"
    )
    ordinate_type_obj = await connection.gettype("MDSYS.SDO_ORDINATE_ARRAY")

    # Convert a Python object to MDSYS.SDO_GEOMETRY
    def sdo_input_type_handler(cursor, value, num_elements):
        def sdo_in_converter(value):
            obj = obj_type.newobject()
            obj.SDO_GTYPE = value.gtype
            obj.SDO_ELEM_INFO = element_info_type_obj.newobject()
            obj.SDO_ELEM_INFO.extend(value.elem_info)
            obj.SDO_ORDINATES = ordinate_type_obj.newobject()
            obj.SDO_ORDINATES.extend(value.ordinates)
            return obj

        if isinstance(value, MySDO):
            return cursor.var(
                obj_type, arraysize=num_elements, inconverter=sdo_in_converter
            )

    # Create and insert a Python object
    sdo = MySDO(2003, [1, 1003, 3], [1, 1, 5, 7])
    cursor.inputtypehandler = sdo_input_type_handler
    await cursor.execute("truncate table TestGeometry")
    await cursor.execute("insert into TestGeometry values (1, :1)", [sdo])

    # Define a function to pretty-print the contents of an Oracle object
    def dump_object(obj, prefix=""):
        if obj.type.iscollection:
            print(f"{prefix}[")
            for value in obj.aslist():
                if isinstance(value, oracledb.DbObject):
                    dump_object(value, prefix + "  ")
                else:
                    print(f"{prefix}  {repr(value)}")
            print(f"{prefix}]")
        else:
            print(f"{prefix}{{")
            for attr in obj.type.attributes:
                value = getattr(obj, attr.name)
                if isinstance(value, oracledb.DbObject):
                    print(f"{prefix}  {attr.name}:")
                    dump_object(value, prefix + "    ")
                else:
                    print(f"{prefix}  {attr.name}: {repr(value)}")
            print(f"{prefix}}}")

    # Query the row back
    await cursor.execute("select geometry from TestGeometry")
    async for (obj,) in cursor:
        dump_object(obj)


asyncio.run(main())
