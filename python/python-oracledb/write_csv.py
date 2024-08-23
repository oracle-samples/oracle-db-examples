# -----------------------------------------------------------------------------
# Copyright (c) 2024, Oracle and/or its affiliates.
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
# write_csv.py
#
# A sample showing one way of writing CSV data.
# -----------------------------------------------------------------------------

import csv

import oracledb
import sample_env

# determine whether to use python-oracledb thin mode or thick mode
if not sample_env.get_is_thin():
    oracledb.init_oracle_client(lib_dir=sample_env.get_oracle_client())

# CSV file to create
FILE_NAME = "sample.csv"


connection = oracledb.connect(
    user=sample_env.get_main_user(),
    password=sample_env.get_main_password(),
    dsn=sample_env.get_connect_string(),
)

with connection.cursor() as cursor:
    cursor.arraysize = 1000  # tune this for large queries
    print(f"Writing to {FILE_NAME}")
    with open(FILE_NAME, "w") as f:
        writer = csv.writer(
            f, lineterminator="\n", quoting=csv.QUOTE_NONNUMERIC
        )
        cursor.execute("""select rownum, sysdate, mycol from BigTab""")
        writer.writerow(info.name for info in cursor.description)
        writer.writerows(cursor)
