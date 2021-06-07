#------------------------------------------------------------------------------
# Copyright (c) 2016, 2021, Oracle and/or its affiliates. All rights reserved.
#
# Portions Copyright 2007-2015, Anthony Tuininga. All rights reserved.
#
# Portions Copyright 2001-2007, Computronix (Canada) Ltd., Edmonton, Alberta,
# Canada. All rights reserved.
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# insert_geometry.py
#   This script demonstrates the ability to create Oracle objects (this example
# uses SDO_GEOMETRY) and insert them into a table.
#
# This script requires cx_Oracle 5.3 and higher.
#------------------------------------------------------------------------------

import cx_Oracle as oracledb
import sample_env

# create and populate Oracle objects
connection = oracledb.connect(sample_env.get_main_connect_string())
type_obj = connection.gettype("MDSYS.SDO_GEOMETRY")
element_info_type_obj = connection.gettype("MDSYS.SDO_ELEM_INFO_ARRAY")
ordinate_type_obj = connection.gettype("MDSYS.SDO_ORDINATE_ARRAY")
obj = type_obj.newobject()
obj.SDO_GTYPE = 2003
obj.SDO_ELEM_INFO = element_info_type_obj.newobject()
obj.SDO_ELEM_INFO.extend([1, 1003, 3])
obj.SDO_ORDINATES = ordinate_type_obj.newobject()
obj.SDO_ORDINATES.extend([1, 1, 5, 7])
print("Created object", obj)

# create table, if necessary
cursor = connection.cursor()
cursor.execute("""
        select count(*)
        from user_tables
        where table_name = 'TESTGEOMETRY'""")
count, = cursor.fetchone()
if count == 0:
    print("Creating table...")
    cursor.execute("""
            create table TestGeometry (
                IntCol number(9) not null,
                Geometry MDSYS.SDO_GEOMETRY not null
            )""")

# remove all existing rows and then add a new one
print("Removing any existing rows...")
cursor.execute("delete from TestGeometry")
print("Adding row to table...")
cursor.execute("insert into TestGeometry values (1, :obj)", obj=obj)
connection.commit()
print("Success!")
