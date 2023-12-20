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
# bind_query.py
#
# Demonstrates the use of bind variables in queries. Binding is important for
# scalability and security.  Since the text of a query that is re-executed is
# unchanged, no additional parsing is required, thereby reducing overhead and
# increasing performance. It also permits data to be bound without having to be
# concerned about escaping special characters, or be concerned about SQL
# injection attacks.
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
)

# Bind by position with lists
with connection.cursor() as cursor:
    print("1. Bind by position: single value list")
    sql = "select * from SampleQueryTab where id = :bvid"
    for row in cursor.execute(sql, [1]):
        print(row)
    print()

    print("2. Bind by position: multiple values")
    sql = "select * from SampleQueryTab where id = :bvid and 123 = :otherbind"
    for row in cursor.execute(sql, [2, 123]):
        print(row)
    print()

    # With bind-by-position, the order of the data in the bind list matches the
    # order of the placeholders used in the SQL statement.  The bind list data
    # order is not associated by the name of the bind variable placeholders in
    # the SQL statement, even though those names are ":1" and ":2".
    print(
        "3. Bind by position: multiple values with numeric placeholder names"
    )
    sql = "select * from SampleQueryTab where id = :2 and 456 = :1"
    for row in cursor.execute(sql, [3, 456]):
        print(row)
    print()

    # With bind-by-position, repeated use of bind placeholder names in the SQL
    # statement requires the input list data to be repeated.
    print("4. Bind by position: multiple values with a repeated placeholder")
    sql = "select * from SampleQueryTab where id = :2 and 3 = :2"
    for row in cursor.execute(sql, [3, 3]):
        print(row)
    print()


# Bind by position with tuples
with connection.cursor() as cursor:
    print("5. Bind by position with single value tuple")
    sql = "select * from SampleQueryTab where id = :bvid"
    for row in cursor.execute(sql, (4,)):
        print(row)
    print()

    print("6. Bind by position with a multiple value tuple")
    sql = "select * from SampleQueryTab where id = :bvid and 789 = :otherbind"
    for row in cursor.execute(sql, (4, 789)):
        print(row)
    print()

# Bind by name with a dictionary
with connection.cursor() as cursor:
    print("7. Bind by name with a dictionary")
    sql = "select * from SampleQueryTab where id = :bvid"
    for row in cursor.execute(sql, {"bvid": 4}):
        print(row)
    print()

    # With bind-by-name, repeated use of bind placeholder names in the SQL
    # statement lets you supply the data once.
    print("8. Bind by name with multiple value dict and repeated placeholders")
    sql = "select * from SampleQueryTab where id = :bvid and 4 = :bvid"
    for row in cursor.execute(sql, {"bvid": 4}):
        print(row)
    print()

# Bind by name with parameters.  The execute() parameter names match the bind
# variable placeholder names.
with connection.cursor() as cursor:
    print("9. Bind by name using parameters")
    sql = "select * from SampleQueryTab where id = :bvid"
    for row in cursor.execute(sql, bvid=5):
        print(row)
    print()

    print("10. Bind by name using multiple parameters")
    sql = "select * from SampleQueryTab where id = :bvid and 101 = :otherbind"
    for row in cursor.execute(sql, bvid=5, otherbind=101):
        print(row)
    print()

    # With bind-by-name, repeated use of bind placeholder names in the SQL
    # statement lets you supply the data once.
    print("11. Bind by name: multiple values with repeated placeholder names")
    sql = "select * from SampleQueryTab where id = :bvid and 6 = :bvid"
    for row in cursor.execute(sql, bvid=6):
        print(row)
    print()

# Rexcuting a query with different data values
with connection.cursor() as cursor:
    sql = "select * from SampleQueryTab where id = :bvid"

    print("12. Query results with id = 7")
    for row in cursor.execute(sql, [4]):
        print(row)
    print()

    print("13. Rexcuted query results with id = 1")
    for row in cursor.execute(sql, [1]):
        print(row)
    print()
