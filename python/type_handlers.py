#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# type_handlers.py
#   This script demonstrates the use of input and output type handlers as well
# as variable input and output converters. These methods can be used to extend
# cx_Oracle in many ways. This script demonstrates the binding and querying of
# SQL objects as Python objects.
#
# This script requires cx_Oracle 5.0 and higher.
#------------------------------------------------------------------------------

import datetime

import cx_Oracle as oracledb
import sample_env

con = oracledb.connect(sample_env.get_main_connect_string())
obj_type = con.gettype("UDT_BUILDING")

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
    return Building(int(obj.BUILDINGID), obj.DESCRIPTION, int(obj.NUMFLOORS),
                    obj.DATEBUILT)


def input_type_handler(cursor, value, num_elements):
    if isinstance(value, Building):
        return cursor.var(obj_type, arraysize=num_elements,
                          inconverter=building_in_converter)

def output_type_handler(cursor, name, default_type, size, precision, scale):
    if default_type == oracledb.OBJECT:
        return cursor.var(obj_type, arraysize=cursor.arraysize,
                          outconverter=building_out_converter)

buildings = [
    Building(1, "The First Building", 5, datetime.date(2007, 5, 18)),
    Building(2, "The Second Building", 87, datetime.date(2010, 2, 7)),
    Building(3, "The Third Building", 12, datetime.date(2005, 6, 19)),
]

cur = con.cursor()
cur.inputtypehandler = input_type_handler
for building in buildings:
    try:
        cur.execute("insert into TestBuildings values (:1, :2)",
                (building.building_id, building))
    except oracledb.DatabaseError as e:
        error, = e.args
        print("CONTEXT:", error.context)
        print("MESSAGE:", error.message)
        raise

print("NO OUTPUT TYPE HANDLER:")
for row in cur.execute("select * from TestBuildings order by BuildingId"):
    print(row)
print()

cur = con.cursor()
cur.outputtypehandler = output_type_handler
print("WITH OUTPUT TYPE HANDLER:")
for row in cur.execute("select * from TestBuildings order by BuildingId"):
    print(row)
print()
