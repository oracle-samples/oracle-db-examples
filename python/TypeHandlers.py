#------------------------------------------------------------------------------
# Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# TypeHandlers.py
#   This script demonstrates the use of input and output type handlers as well
# as variable input and output converters. These methods can be used to extend
# cx_Oracle in many ways. This script demonstrates the binding and querying of
# SQL objects as Python objects.
#
# This script requires cx_Oracle 5.0 and higher.
#------------------------------------------------------------------------------


from __future__ import print_function

import cx_Oracle
import datetime
import SampleEnv

con = cx_Oracle.connect(SampleEnv.GetMainConnectString())
objType = con.gettype("UDT_BUILDING")

class Building(object):

    def __init__(self, buildingId, description, numFloors, dateBuilt):
        self.buildingId = buildingId
        self.description = description
        self.numFloors = numFloors
        self.dateBuilt = dateBuilt

    def __repr__(self):
        return "<Building %s: %s>" % (self.buildingId, self.description)


def BuildingInConverter(value):
    obj = objType.newobject()
    obj.BUILDINGID = value.buildingId
    obj.DESCRIPTION = value.description
    obj.NUMFLOORS = value.numFloors
    obj.DATEBUILT = value.dateBuilt
    return obj


def BuildingOutConverter(obj):
    return Building(int(obj.BUILDINGID), obj.DESCRIPTION, int(obj.NUMFLOORS),
            obj.DATEBUILT)


def InputTypeHandler(cursor, value, numElements):
    if isinstance(value, Building):
        return cursor.var(cx_Oracle.OBJECT, arraysize = numElements,
                inconverter = BuildingInConverter, typename = objType.name)

def OutputTypeHandler(cursor, name, defaultType, size, precision, scale):
    if defaultType == cx_Oracle.OBJECT:
        return cursor.var(cx_Oracle.OBJECT, arraysize = cursor.arraysize,
                outconverter = BuildingOutConverter, typename = objType.name)

buildings = [
    Building(1, "The First Building", 5, datetime.date(2007, 5, 18)),
    Building(2, "The Second Building", 87, datetime.date(2010, 2, 7)),
    Building(3, "The Third Building", 12, datetime.date(2005, 6, 19)),
]

cur = con.cursor()
cur.inputtypehandler = InputTypeHandler
for building in buildings:
    try:
        cur.execute("insert into TestBuildings values (:1, :2)",
                (building.buildingId, building))
    except cx_Oracle.DatabaseError as e:
        error, = e.args
        print("CONTEXT:", error.context)
        print("MESSAGE:", error.message)
        raise

print("NO OUTPUT TYPE HANDLER:")
for row in cur.execute("select * from TestBuildings order by BuildingId"):
    print(row)
print()

cur = con.cursor()
cur.outputtypehandler = OutputTypeHandler
print("WITH OUTPUT TYPE HANDLER:")
for row in cur.execute("select * from TestBuildings order by BuildingId"):
    print(row)
print()

