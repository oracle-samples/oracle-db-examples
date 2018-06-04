/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved. */

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
 *   em_dmlreturn2_aa.js
 *
 * DESCRIPTION
 *   executeMany() example of DML RETURNING that returns multiple values
 *   This example also uses Async/Await of Node 8.
 *   Use demo.sql to create the required schema.
 *
 *****************************************************************************/

var oracledb = require('oracledb');
var dbConfig = require('./dbconfig.js');

const truncateSql = "TRUNCATE TABLE em_tab";

const insertSql = "INSERT INTO em_tab VALUES (:1, :2)";

const insertData = [
  [1, "Test 1 (One)"],
  [2, "Test 2 (Two)"],
  [3, "Test 3 (Three)"],
  [4, "Test 4 (Four)"],
  [5, "Test 5 (Five)"],
  [6, "Test 6 (Six)"],
  [7, "Test 7 (Seven)"],
  [8, "Test 8 (Eight)"]
];

const insertOptions = {
  bindDefs: [
    { type: oracledb.NUMBER },
    { type: oracledb.STRING, maxSize: 20 }
  ]
};

const deleteSql = "DELETE FROM em_tab WHERE id < :1 RETURNING id, val INTO :2, :3";

const deleteData = [
  [2],
  [6],
  [8]
];

const deleteOptions = {
  bindDefs: [
    { type: oracledb.NUMBER },
    { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
    { type: oracledb.STRING, maxSize: 25, dir: oracledb.BIND_OUT }
  ]
};

async function run() {
  let conn;
  let result;

  try {
    conn = await oracledb.getConnection(dbConfig);

    await conn.execute(truncateSql);

    await conn.executeMany(insertSql, insertData, insertOptions);

    result = await conn.executeMany(deleteSql, deleteData, deleteOptions);

    console.log("rowsAffected is:", result.rowsAffected);
    console.log("Out binds:");
    for (let i = 0; i < result.outBinds.length; i++) {
      console.log("-->", result.outBinds[i]);
    }

  } catch (err) {
    console.error(err);
  } finally {
    if (conn) {
      try {
        await conn.close();
      } catch (err) {
        console.error(err);
      }
    }
  }
}

run();
