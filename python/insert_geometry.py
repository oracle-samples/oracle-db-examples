#------------------------------------------------------------------------------
# Copyright (c) 2016, 2022, Oracle and/or its affiliates.
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
#------------------------------------------------------------------------------

#------------------------------------------------------------------------------
# insert_geometry.py
#
# Demonstrates the ability to create Oracle objects (this example uses
# SDO_GEOMETRY) and insert them into a table.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

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
