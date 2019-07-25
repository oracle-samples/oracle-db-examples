/* Copyright (c) 2016, 2019, Oracle and/or its affiliates. All rights reserved. */

/******************************************************************************
 *
 * You may not use the identified files except in compliance with the Apache
 * License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at
 * http://www.apache.org/licenses/LICENSE-2.0.
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * NAME
 *   plsqlarray.js
 *
 * DESCRIPTION
 *   Examples of binding PL/SQL "INDEX BY" tables.  Beach names and
 *   water depths are passed into the first PL/SQL procedure which
 *   inserts them into a table.  The second PL/SQL procedure queries
 *   that table and returns the values.  The third procedure accepts
 *   arrays, and returns the values sorted by the beach name.
 *
 *   Use demo.sql to create the required tables and package.
 *
 *   This example requires node-oracledb 1.6 or later.
 *
 *   This example uses Node 8's async/await syntax.
 *
 *****************************************************************************/

const oracledb = require('oracledb');
const dbConfig = require('./dbconfig.js');

async function run() {

  let connection;

  try {
    connection = await oracledb.getConnection(dbConfig);

    let result;

    // PL/SQL array bind IN parameters:
    // Pass arrays of values to a PL/SQL procedure
    await connection.execute(
      `BEGIN
         beachpkg.array_in(:beach_in, :depth_in);
       END;`,
      {
        beach_in:
        { type : oracledb.STRING,
          dir: oracledb.BIND_IN,
          val: ["Malibu Beach", "Bondi Beach", "Waikiki Beach"] },
        depth_in:
        { type : oracledb.NUMBER,
          dir: oracledb.BIND_IN,
          val: [45, 30, 67] }
      });
    console.log('Data was bound in successfully');

    // PL/SQL array bind OUT parameters:
    // Fetch arrays of values from a PL/SQL procedure
    result = await connection.execute(
      `BEGIN
         beachpkg.array_out(:beach_out, :depth_out);
       END;`,
      {
        beach_out:
        { type: oracledb.STRING,
          dir: oracledb.BIND_OUT,
          maxArraySize: 3 },
        depth_out:
        { type: oracledb.NUMBER,
          dir: oracledb.BIND_OUT,
          maxArraySize: 3 }
      });
    console.log("Binds returned:");
    console.log(result.outBinds);

    // PL/SQL array bind IN OUT parameters:
    // Return input arrays sorted by beach name
    result = await connection.execute(
      `BEGIN
         beachpkg.array_inout(:beach_inout, :depth_inout);
       END;`,
      {
        beach_inout:
        { type: oracledb.STRING,
          dir: oracledb.BIND_INOUT,
          val: ["Port Melbourne Beach", "Eighty Mile Beach", "Chesil Beach"],
          maxArraySize: 6 },
        depth_inout:
        { type: oracledb.NUMBER,
          dir: oracledb.BIND_INOUT,
          val: [8, 3, 70],
          maxArraySize: 6 }
      });
    console.log("Binds returned:");
    console.log(result.outBinds);

  } catch (err) {
    console.error(err);
  } finally {
    if (connection) {
      try {
        await connection.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

run();
