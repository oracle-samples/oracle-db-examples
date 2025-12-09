# -----------------------------------------------------------------------------
# Copyright (c) 2025, Oracle and/or its affiliates.
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
# dataframe_parquet_write.py
#
# Shows how to use connection.fetch_df_batches() to write files in Parquet
# format.
# -----------------------------------------------------------------------------

import os

import pyarrow
import pyarrow.parquet as pq

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

PARQUET_FILE_NAME = "sample.parquet"

if os.path.isfile(PARQUET_FILE_NAME):
    os.remove(PARQUET_FILE_NAME)

# Tune this for your query
FETCH_BATCH_SIZE = 10

SQL = "select id, name from SampleQueryTab order by id"
pqwriter = None

for odf in connection.fetch_df_batches(statement=SQL, size=FETCH_BATCH_SIZE):

    pyarrow_table = pyarrow.table(odf)

    if not pqwriter:
        pqwriter = pq.ParquetWriter(PARQUET_FILE_NAME, pyarrow_table.schema)

    print(f"Writing a batch of {odf.num_rows()} rows")
    pqwriter.write_table(pyarrow_table)

pqwriter.close()

# -----------------------------------------------------------------------------
# Check the file was created

print("\nParquet file metadata:")
print(pq.read_metadata(PARQUET_FILE_NAME))

# -----------------------------------------------------------------------------
# Read the file

print("\nParquet file data:")
t = pq.read_table(PARQUET_FILE_NAME, columns=["ID", "NAME"])
print(t)
