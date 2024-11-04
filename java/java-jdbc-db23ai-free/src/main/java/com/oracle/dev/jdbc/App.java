/*
  Copyright (c) 2024, Oracle and/or its affiliates.

  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

package com.oracle.dev.jdbc;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;

import oracle.jdbc.pool.OracleDataSource;

public class App {
  public static void main(String[] args) throws SQLException {
    OracleDataSource ods = new OracleDataSource();
    // jdbc:oracle:thin@[hostname]:[port]/[DB service/name]
    ods.setURL("jdbc:oracle:thin:@localhost:1521/FREEPDB1");
    ods.setUser("[Username]");
    ods.setPassword("[Password]");
    try (Connection conn = ods.getConnection();
        PreparedStatement stmt = conn
            .prepareStatement("SELECT 'Hello World!' FROM dual");
        ResultSet rslt = stmt.executeQuery();) {
      while (rslt.next()) {
        System.out.println(rslt.getString(1));
      }
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
}
