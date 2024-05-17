# -----------------------------------------------------------------------------
# Copyright (c) 2020, 2023, Oracle and/or its affiliates.
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
# drop_schema.py
#
# Drops the database objects used by the python-oracledb samples.
#
# This script is also executed by the Python script sample_setup.py for
# dropping the existing users and editions, if applicable, before creating the
# sample schemas and editions.
# -----------------------------------------------------------------------------

import sample_env


def drop_schema(conn):
    print("Dropping sample schemas and edition...")
    sample_env.run_sql_script(
        conn,
        "drop_schema",
        main_user=sample_env.get_main_user(),
        edition_user=sample_env.get_edition_user(),
        edition_name=sample_env.get_edition_name(),
    )


if __name__ == "__main__":
    conn = sample_env.get_admin_connection()
    drop_schema(conn)
    print("Done.")
