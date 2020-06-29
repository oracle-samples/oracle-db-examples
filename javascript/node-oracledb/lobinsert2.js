/* Copyright (c) 2015, 2020, Oracle and/or its affiliates. All rights reserved. */

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
 *   lobinsert2.js
 *
 * DESCRIPTION
 *   INSERTs text into a CLOB column using the 'RETURNING INTO' method.
 *
 *   For smaller LOBs you will probably prefer the method shown in lobinsert1.js
 *
 *   This example requires node-oracledb 1.12 or later.
 *
 *****************************************************************************/

const fs = require('fs');
const oracledb = require('oracledb');
const dbConfig = require('./dbconfig.js');
const demoSetup = require('./demosetup.js');

const inFileName = 'clobexample.txt';  // the file with text to be inserted into the database

async function run() {

  let connection;

  try {
    const connection = await oracledb.getConnection(dbConfig);

    await demoSetup.setupLobs(connection);  // create the demo table

    const result = await connection.execute(
      `INSERT INTO no_lobs (id, c) VALUES (:id, EMPTY_CLOB()) RETURNING c INTO :lobbv`,
      {
        id: 4,
        lobbv: {type: oracledb.CLOB, dir: oracledb.BIND_OUT}
      },
      { autoCommit: false }  // a transaction needs to span the INSERT and pipe()
    );

    if (result.rowsAffected != 1 || result.outBinds.lobbv.length != 1) {
      throw new Error('Error getting a LOB locator');
    }

    const lob = result.outBinds.lobbv[0];
    if (lob === null) {
      throw new Error('NULL lob found');
    }

    const doStream = new Promise((resolve, reject) => {

      lob.on('finish', () => {
        // console.log("lob.on 'finish' event");
        connection.commit((err) => {
          if (err) {
            lob.destroy(err);
          } else {
            console.log("Text inserted successfully.");
            resolve();
          }
        });
      });

      lob.on('error', (err) => {
        // console.log("lob.on 'error' event");
        reject(err);
      });

      console.log('Reading from ' + inFileName);
      const inStream = fs.createReadStream(inFileName);
      inStream.on('error', (err) => {
        // console.log("inStream.on 'error' event");
        lob.destroy(err);
      });

      inStream.pipe(lob);  // copies the text to the LOB
    });

    await doStream;

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
