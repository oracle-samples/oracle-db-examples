# -----------------------------------------------------------------------------
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
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# plsql_record.py
#
# Demonstrates how to bind (IN and OUT) a PL/SQL record.
#
# This feature is only available in Oracle Database 12.1 and higher.
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

# create new object of the correct type
# note the use of a PL/SQL record defined in a package
# a table record identified by TABLE%ROWTYPE can also be used
type_obj = connection.gettype("PKG_DEMO.UDT_DEMORECORD")
obj = type_obj.newobject()
obj.NUMBERVALUE = 6
obj.STRINGVALUE = "Test String"
obj.DATEVALUE = datetime.datetime(2016, 5, 28)
obj.BOOLEANVALUE = False

# show the original values
print("NUMBERVALUE ->", obj.NUMBERVALUE)
print("STRINGVALUE ->", obj.STRINGVALUE)
print("DATEVALUE ->", obj.DATEVALUE)
print("BOOLEANVALUE ->", obj.BOOLEANVALUE)
print()

with connection.cursor() as cursor:
    # call the stored procedure which will modify the object
    cursor.callproc("pkg_Demo.DemoRecordsInOut", (obj,))

    # show the modified values
    print("NUMBERVALUE ->", obj.NUMBERVALUE)
    print("STRINGVALUE ->", obj.STRINGVALUE)
    print("DATEVALUE ->", obj.DATEVALUE)
    print("BOOLEANVALUE ->", obj.BOOLEANVALUE)
    print()
