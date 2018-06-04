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
 *   em_dmlreturn2.js
 *
 * DESCRIPTION
 *   executeMany() example of DML RETURNING that returns multiple values
 *   Use demo.sql to create the required schema.
 *
 *****************************************************************************/

var async = require('async');
var oracledb = require('oracledb');
var dbConfig = require('./dbconfig.js');

var doconnect = function(cb) {
  oracledb.getConnection(dbConfig, cb);
};

var dorelease = function(conn) {
  conn.close(function (err) {
    if (err)
      console.error(err.message);
  });
};

var dotruncate = function(conn, cb) {
  conn.execute("TRUNCATE TABLE em_tab", function (err) {
    return cb(err, conn);
  });
};

var doinsert = function(conn, cb) {
  var sql = "INSERT INTO em_tab VALUES (:1, :2)";

  var binds = [
    [1, "Test 1 (One)"],
    [2, "Test 2 (Two)"],
    [3, "Test 3 (Three)"],
    [4, "Test 4 (Four)"],
    [5, "Test 5 (Five)"],
    [6, "Test 6 (Six)"],
    [7, "Test 7 (Seven)"],
    [8, "Test 8 (Eight)"]
  ];

  var options = {
    bindDefs: [
      { type: oracledb.NUMBER },
      { type: oracledb.STRING, maxSize: 20 }
    ]
  };

  conn.executeMany(sql, binds, options, function (err) {
    return cb(err, conn);
  });
};

var dodelete = function(conn, cb) {
  var sql = "DELETE FROM em_tab WHERE id < :1 RETURNING id, val INTO :2, :3";

  var binds = [
    [2],
    [6],
    [8]
  ];

  var options = {
    bindDefs: [
      { type: oracledb.NUMBER },
      { type: oracledb.NUMBER, dir: oracledb.BIND_OUT },
      { type: oracledb.STRING, maxSize: 25, dir: oracledb.BIND_OUT }
    ]
  };

  conn.executeMany(sql, binds, options, function (err, result) {
    if (err)
      return cb(err, conn);
    else {
      console.log("rowsAffected is:", result.rowsAffected);
      console.log("Out binds:");
      for (let i = 0; i < result.outBinds.length; i++) {
        console.log("-->", result.outBinds[i]);
      }
      return cb(null, conn);
    }
  });
};

async.waterfall(
  [
    doconnect,
    dotruncate,
    doinsert,
    dodelete
  ],
  function (err, conn) {
    if (err) { console.error("In waterfall error cb: ==>", err, "<=="); }
    if (conn)
      dorelease(conn);
  });
