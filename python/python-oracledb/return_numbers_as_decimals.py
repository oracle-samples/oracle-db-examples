#------------------------------------------------------------------------------
# Copyright (c) 2017, 2022, Oracle and/or its affiliates.
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
# return_numbers_as_decimals.py
#
# Returns all numbers as decimals. This is needed if the full decimal
# precision of Oracle numbers is required by the application. See this article
# (http://blog.reverberate.org/2016/02/06/floating-point-demystified-part2.html)
# for an explanation of why decimal numbers (like Oracle numbers) cannot be
# represented exactly by floating point numbers.
#------------------------------------------------------------------------------

import decimal

import oracledb
import sample_env

# indicate that numbers should be fetched as decimals
oracledb.defaults.fetch_decimals = True

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

connection = oracledb.connect(user=sample_env.get_main_user(),
                              password=sample_env.get_main_password(),
                              dsn=sample_env.get_connect_string())

with connection.cursor() as cursor:
    cursor.execute("select * from TestNumbers")
    for row in cursor:
        print("Row:", row)
