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
# implicit_results.py
#
# Demonstrates the use of the Oracle Database 12.1 feature that allows PL/SQL
# procedures to return result sets implicitly, without having to explicitly
# define them.
#------------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string())

with connection.cursor() as cursor:

    # A PL/SQL block that returns two cursors
    cursor.execute("""
            declare
                c1 sys_refcursor;
                c2 sys_refcursor;
            begin

                open c1 for
                    select * from TestNumbers;

                dbms_sql.return_result(c1);

                open c2 for
                    select * from TestStrings;

                dbms_sql.return_result(c2);

            end;""")

    # display results
    for ix, result_set in enumerate(cursor.getimplicitresults()):
        print("Result Set #" + str(ix + 1))
        for row in result_set:
            print(row)
        print()
