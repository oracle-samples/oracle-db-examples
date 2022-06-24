# -----------------------------------------------------------------------------
# Copyright (c) 2022, Oracle and/or its affiliates.
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
# type_handlers_json_strings.py
#
# Demonstrates the use of input and output type handlers as well as variable
# input and output converters. These methods can be used to extend
# python-oracledb in many ways.
#
# This script differs from type_handlers_objects.py in that it shows the
# binding and querying of JSON strings as Python objects for both
# python-oracledb thin and thick mode.
#------------------------------------------------------------------------------

import json

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

class Building:

    def __init__(self, building_id, description, num_floors):
        self.building_id = building_id
        self.description = description
        self.num_floors = num_floors

    def __repr__(self):
        return "<Building %s: %s>" % (self.building_id, self.description)

    def __eq__(self, other):
        if isinstance(other, Building):
            return other.building_id == self.building_id \
                    and other.description == self.description \
                    and other.num_floors == self.num_floors
        return NotImplemented

    def to_json(self):
        return json.dumps(self.__dict__)

    @classmethod
    def from_json(cls, value):
        result = json.loads(value)
        return cls(**result)


def building_in_converter(value):
        return value.to_json()


def input_type_handler(cursor, value, num_elements):
    if isinstance(value, Building):
        return cursor.var(oracledb.STRING, arraysize=num_elements,
                          inconverter=building_in_converter)


def output_type_handler(cursor, name, default_type, size, precision, scale):
    if default_type == oracledb.STRING:
        return cursor.var(default_type, arraysize=cursor.arraysize,
                          outconverter=Building.from_json)

conn = oracledb.connect(sample_env.get_main_connect_string())
cur = conn.cursor()

buildings = [
    Building(1, "The First Building", 5),
    Building(2, "The Second Building", 87),
    Building(3, "The Third Building", 12)
]

# Insert building data (python object) as a JSON string
cur.inputtypehandler = input_type_handler
for building in buildings:
    cur.execute("insert into BuildingsAsJsonStrings values (:1, :2)",
                (building.building_id, building))

# fetch the building data as a JSON string
print("NO OUTPUT TYPE HANDLER:")
for row in cur.execute("""
        select * from BuildingsAsJsonStrings
        order by BuildingId"""):
    print(row)
print()

cur = conn.cursor()

# fetch the building data as python objects
cur.outputtypehandler = output_type_handler
print("WITH OUTPUT TYPE HANDLER:")
for row in cur.execute("""
        select * from BuildingsAsJsonStrings
        order by BuildingId"""):
    print(row)
print()
