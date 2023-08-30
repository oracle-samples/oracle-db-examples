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
# scrollable_cursors.py
#
# Demonstrates how to use scrollable cursors. These allow moving forward and
# backward in the result set but incur additional overhead on the server to
# retain this information.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# this script is currently only supported in python-oracledb thick mode
oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string())

# show all of the rows available in the table
with connection.cursor() as cursor:
    cursor.execute("select * from TestStrings order by IntCol")
    print("ALL ROWS")
    for row in cursor:
        print(row)
    print()

# create a scrollable cursor
with connection.cursor(scrollable = True) as cursor:
    # set array size smaller than the default (100) to force scrolling by the
    # database; otherwise, scrolling occurs directly within the buffers
    cursor.arraysize = 3
    cursor.execute("select * from TestStrings order by IntCol")

    # scroll to last row in the result set; the first parameter is not needed
    # and is ignored)
    cursor.scroll(mode = "last")
    print("LAST ROW")
    print(cursor.fetchone())
    print()

    # scroll to the first row in the result set; the first parameter not needed
    # and is ignored
    cursor.scroll(mode = "first")
    print("FIRST ROW")
    print(cursor.fetchone())
    print()

    # scroll to an absolute row number
    cursor.scroll(5, mode = "absolute")
    print("ROW 5")
    print(cursor.fetchone())
    print()

    # scroll forward six rows (the mode parameter defaults to relative)
    cursor.scroll(3)
    print("SKIP 3 ROWS")
    print(cursor.fetchone())
    print()

    # scroll backward four rows (the mode parameter defaults to relative)
    cursor.scroll(-4)
    print("SKIP BACK 4 ROWS")
    print(cursor.fetchone())
    print()
