# -----------------------------------------------------------------------------
# Copyright (c) 2016, 2023, Oracle and/or its affiliates.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
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
# type_handlers_objects.py
#
# Demonstrates the use of input and output type handlers as well as variable
# input and output converters. These methods can be used to extend
# python-oracledb in many ways. This script demonstrates the binding and
# querying of SQL objects as Python objects.
# -----------------------------------------------------------------------------

import datetime

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

obj_type = connection.gettype("UDT_BUILDING")


class Building:
    def __init__(self, building_id, description, num_floors, date_built):
        self.building_id = building_id
        self.description = description
        self.num_floors = num_floors
        self.date_built = date_built

    def __repr__(self):
        return "<Building %s: %s>" % (self.building_id, self.description)


def building_in_converter(value):
    obj = obj_type.newobject()
    obj.BUILDINGID = value.building_id
    obj.DESCRIPTION = value.description
    obj.NUMFLOORS = value.num_floors
    obj.DATEBUILT = value.date_built
    return obj


def building_out_converter(obj):
    return Building(
        int(obj.BUILDINGID), obj.DESCRIPTION, int(obj.NUMFLOORS), obj.DATEBUILT
    )


def input_type_handler(cursor, value, num_elements):
    if isinstance(value, Building):
        return cursor.var(
            obj_type, arraysize=num_elements, inconverter=building_in_converter
        )


def output_type_handler(cursor, metadata):
    if metadata.type_code is oracledb.DB_TYPE_OBJECT:
        return cursor.var(
            metadata.type,
            arraysize=cursor.arraysize,
            outconverter=building_out_converter,
        )


buildings = [
    Building(1, "The First Building", 5, datetime.date(2007, 5, 18)),
    Building(2, "The Second Building", 87, datetime.date(2010, 2, 7)),
    Building(3, "The Third Building", 12, datetime.date(2005, 6, 19)),
]

with connection.cursor() as cursor:
    cursor.inputtypehandler = input_type_handler
    for building in buildings:
        cursor.execute(
            "insert into BuildingsAsObjects values (:1, :2)",
            (building.building_id, building),
        )

    print("NO OUTPUT TYPE HANDLER:")
    for row in cursor.execute(
        """
        select *
        from BuildingsAsObjects
        order by BuildingId
        """
    ):
        print(row)
    print()

with connection.cursor() as cursor:
    cursor.outputtypehandler = output_type_handler
    print("WITH OUTPUT TYPE HANDLER:")
    for row in cursor.execute(
        """
        select *
        from BuildingsAsObjects
        order by BuildingId
        """
    ):
        print(row)
    print()
