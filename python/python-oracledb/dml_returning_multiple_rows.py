# -----------------------------------------------------------------------------
# Copyright (c) 2017, 2024, Oracle and/or its affiliates.
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
# dml_returning_multiple_rows.py
#
# Demonstrates the use of DML returning with multiple rows being returned at
# once.
# -----------------------------------------------------------------------------

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
    params=sample_env.get_connect_params(),
)

with connection.cursor() as cursor:
    # truncate table first so that script can be rerun
    print("Truncating table...")
    cursor.execute("truncate table TestTempTable")

    # populate table with a few rows
    for i in range(5):
        data = (i + 1, "Test String #%d" % (i + 1))
        print("Adding row", data)
        cursor.execute("insert into TestTempTable values (:1, :2)", data)

    # now delete them and use DML returning to return the data that was
    # deleted
    int_col = cursor.var(int)
    string_col = cursor.var(str)
    print("Deleting data with DML returning...")
    cursor.execute(
        """
        delete from TestTempTable
        returning IntCol, StringCol into :int_col, :string_col
        """,
        int_col=int_col,
        string_col=string_col,
    )
    print("Data returned:")
    for int_val, string_val in zip(int_col.getvalue(), string_col.getvalue()):
        print(tuple([int_val, string_val]))
