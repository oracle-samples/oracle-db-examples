# -----------------------------------------------------------------------------
# Copyright (c) 2023, 2024, Oracle and/or its affiliates.
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
# bind_query_async.py
#
# An asynchronous version of bind_query.py
#
# Demonstrates the use of bind variables in queries. Binding is important for
# scalability and security.  Since the text of a query that is re-executed is
# unchanged, no additional parsing is required, thereby reducing overhead and
# increasing performance. It also permits data to be bound without having to be
# concerned about escaping special characters, or be concerned about SQL
# injection attacks.
# -----------------------------------------------------------------------------

import asyncio

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    # Bind by position with lists
    print("1. Bind by position: single value list")
    sql = "select * from SampleQueryTab where id = :bvid"
    print(await connection.fetchone(sql, [1]))
    print()

    print("2. Bind by position: multiple values")
    sql = "select * from SampleQueryTab where id = :bvid and 123 = :otherbind"
    print(await connection.fetchone(sql, [2, 123]))
    print()

    # With bind-by-position, the order of the data in the bind list matches
    # the order of the placeholders used in the SQL statement.  The bind
    # list data order is not associated by the name of the bind variable
    # placeholders in the SQL statement, even though those names are ":1"
    # and ":2".
    print(
        "3. Bind by position: multiple values with numeric placeholder names"
    )
    sql = "select * from SampleQueryTab where id = :2 and 456 = :1"
    print(await connection.fetchone(sql, [3, 456]))
    print()

    # With bind-by-position, repeated use of bind placeholder names in the
    # SQL statement requires the input list data to be repeated.
    print("4. Bind by position: multiple values with a repeated placeholder")
    sql = "select * from SampleQueryTab where id = :2 and 3 = :2"
    print(await connection.fetchall(sql, [3, 3]))
    print()

    # Bind by position with tuples
    print("5. Bind by position with single value tuple")
    sql = "select * from SampleQueryTab where id = :bvid"
    print(await connection.fetchone(sql, (4,)))
    print()

    print("6. Bind by position with a multiple value tuple")
    sql = "select * from SampleQueryTab where id = :bvid and 789 = :otherbind"
    print(await connection.fetchone(sql, (4, 789)))
    print()

    # Bind by name with a dictionary
    print("7. Bind by name with a dictionary")
    sql = "select * from SampleQueryTab where id = :bvid"
    print(await connection.fetchone(sql, {"bvid": 4}))
    print()

    # With bind-by-name, repeated use of bind placeholder names in the SQL
    # statement lets you supply the data once.
    print("8. Bind by name with multiple value dict and repeated placeholders")
    sql = "select * from SampleQueryTab where id = :bvid and 4 = :bvid"
    print(await connection.fetchone(sql, {"bvid": 4}))
    print()

    # Bind by name with parameters.  The execute() parameter names match the
    # bind variable placeholder names.
    print("9. Bind by name using parameters")
    sql = "select * from SampleQueryTab where id = :bvid"
    print(await connection.fetchone(sql, dict(bvid=5)))
    print()

    print("10. Bind by name using multiple parameters")
    sql = "select * from SampleQueryTab where id = :bvid and 101 = :otherbind"
    print(await connection.fetchone(sql, dict(bvid=5, otherbind=101)))
    print()

    # With bind-by-name, repeated use of bind placeholder names in the SQL
    # statement lets you supply the data once.
    print("11. Bind by name: multiple values with repeated placeholder names")
    sql = "select * from SampleQueryTab where id = :bvid and 6 = :bvid"
    print(await connection.fetchone(sql, dict(bvid=6)))
    print()

    # Rexcuting a query with different data values
    sql = "select * from SampleQueryTab where id = :bvid"

    print("12. Query results with id = 7")
    print(await connection.fetchone(sql, [4]))
    print()

    print("13. Rexcuted query results with id = 1")
    print(await connection.fetchone(sql, [1]))
    print()


asyncio.run(main())
