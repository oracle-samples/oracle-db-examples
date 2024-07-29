/*
 * Copyright (c) 2024, Oracle and/or its affiliates.
 *
 *   This software is dual-licensed to you under the Universal Permissive License
 *   (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
 *   2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
 *   either license.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *
 */

package com.oracle.jdbc.samples.interceptor;


import oracle.jdbc.datasource.impl.OracleDataSource;

import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.ConsoleHandler;
import java.util.logging.Logger;

/**
 * Class to demonstrate the use of round-trips hooks.
 */
public class Main {
  public static void main(String[] args) throws SQLException {

    System.out.println("Application started");


    Connection cnx = null;
    try {
      cnx = connect();
    } catch (SQLException e) {
      e.printStackTrace(System.err);
      System.exit(1);
    }

    Logger.getLogger(SQLStatementInterceptor.ACTION_LOGGER_NAME).addHandler(new ConsoleHandler());


    try (Statement stm = cnx.createStatement()) {
      stm.executeQuery("SELECT 1 FROM DUAL");
    } catch (SQLException e) {
      e.printStackTrace(System.err);
      System.exit(1);
    }
    cnx.close();
    System.out.println("Application ended");
    System.exit(0);
  }


  static Connection connect() throws SQLException, IllegalStateException {
    String url = System.getProperty("com.oracle.jdbc.samples.url");
    String user = System.getProperty("com.oracle.jdbc.samples.user");
    String password = System.getProperty("com.oracle.jdbc.samples.password");
    if (user == null || password == null || url == null) {
      throw new IllegalStateException("please provide a username/password/url");
    }

    OracleDataSource ds = new OracleDataSource();

    ds.setConnectionProperty("oracle.jdbc.provider.traceEventListener",
      "com.oracle.jdbc.samples.interceptor.SQLStatementInterceptorProvider");
    ds.setConnectionProperty("oracle.jdbc.provider.traceEventListener.configuration",
      Main.class.getClassLoader().getResource("rules.json").getPath());
    ds.setURL(url);
    ds.setUser(user);
    ds.setPassword(password);
    return ds.getConnection();
  }

}
