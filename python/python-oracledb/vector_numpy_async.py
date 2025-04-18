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
# vector_numpy_async.py
#
# An asynchronous version of vector_numpy.py
#
# Demonstrates how to use the Oracle Database 23ai VECTOR data type with NumPy
# types.
# -----------------------------------------------------------------------------

import array
import asyncio
import numpy
import sys

import oracledb
import sample_env


async def main():
    connection = await oracledb.connect_async(
        user=sample_env.get_main_user(),
        password=sample_env.get_main_password(),
        dsn=sample_env.get_connect_string(),
        params=sample_env.get_connect_params(),
    )

    # this script only works with Oracle Database 23.5 or later
    if sample_env.get_server_version() < (23, 5):
        sys.exit("This example requires Oracle Database 23.5 or later.")

    # Convert from NumPy ndarray types to array types when inserting vectors
    def numpy_converter_in(value):
        if value.dtype == numpy.float64:
            dtype = "d"
        elif value.dtype == numpy.float32:
            dtype = "f"
        elif value.dtype == numpy.uint8:
            dtype = "B"
        else:
            dtype = "b"
        return array.array(dtype, value)

    def input_type_handler(cursor, value, arraysize):
        if isinstance(value, numpy.ndarray):
            return cursor.var(
                oracledb.DB_TYPE_VECTOR,
                arraysize=arraysize,
                inconverter=numpy_converter_in,
            )

    connection.inputtypehandler = input_type_handler

    # Convert from array types to NumPy ndarray types when fetching vectors
    def numpy_converter_out(value):
        return numpy.array(value, copy=False, dtype=value.typecode)

    def output_type_handler(cursor, metadata):
        if metadata.type_code is oracledb.DB_TYPE_VECTOR:
            return cursor.var(
                metadata.type_code,
                arraysize=cursor.arraysize,
                outconverter=numpy_converter_out,
            )

    connection.outputtypehandler = output_type_handler

    with connection.cursor() as cursor:
        # Insert
        vector_data_32 = numpy.array([1.625, 1.5, 1.0], dtype=numpy.float32)
        vector_data_64 = numpy.array([11.25, 11.75, 11.5], dtype=numpy.float64)
        vector_data_8 = numpy.array([1, 2, 3], dtype=numpy.int8)
        vector_data_vb = numpy.array([180, 150, 100], dtype=numpy.uint8)

        await cursor.execute(
            """insert into SampleVectorTab (v32, v64, v8, vbin)
               values (:1, :2, :3, :4)""",
            [vector_data_32, vector_data_64, vector_data_8, vector_data_vb],
        )

        # Query
        await cursor.execute("select * from SampleVectorTab")

        # Each vector is represented as a numpy.ndarray type
        async for row in cursor:
            print(row)


asyncio.run(main())
