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

package com.oracle.jdbc.reactive;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.sql.SQLException;
import java.util.Properties;

public class DatabaseConfig {

  private static final ConfigData CONFIG_DATA = loadConfig();

  private static ConfigData loadConfig() {
    Properties properties = new Properties();
    try {
      var fileStream = Files.newInputStream(Path.of("src/main/resources/config.properties"));
      properties.load(fileStream);
      return new ConfigData(properties.getProperty("DRIVER"), properties.getProperty("USER"),
          properties.getProperty("PASSWORD"), properties.getProperty("HOST"),
          Integer.parseInt(properties.getProperty("PORT")), properties.getProperty("DATABASE"),
          properties.getProperty("DB_TABLE_NAME"));
    } catch (IOException e) {
      e.printStackTrace();
      return null;
    }
  }

  public static OracleDataSource getDataSource() throws SQLException {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration data is not available, check file path.");
    }
    OracleDataSource dataSource = new OracleDataSource();
    dataSource
        .setURL("jdbc:oracle:thin:@" + CONFIG_DATA.host() + ":" + CONFIG_DATA.port() + "/" + CONFIG_DATA.database());
    dataSource.setUser(CONFIG_DATA.user());
    dataSource.setPassword(CONFIG_DATA.password());
    return dataSource;
  }

  public static OracleConnection getConnection() throws SQLException {
    return (OracleConnection) getDataSource().getConnection();
  }

  public static String getDbTableName() {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration could not be loaded.");
    }
    return CONFIG_DATA.dbTableName();
  }

  public static String getDriver() {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration could not be loaded.");
    }
    return CONFIG_DATA.driver();
  }

  public static String getUser() {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration could not be loaded.");
    }
    return CONFIG_DATA.user();
  }

  public static String getPassword() {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration could not be loaded.");
    }
    return CONFIG_DATA.password();
  }

  public static String getHost() {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration could not be loaded.");
    }
    return CONFIG_DATA.host();
  }

  public static int getPort() {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration could not be loaded.");
    }
    return CONFIG_DATA.port();
  }

  public static String getDatabase() {
    if (CONFIG_DATA == null) {
      throw new IllegalStateException("Configuration could not be loaded.");
    }
    return CONFIG_DATA.database();
  }

  private record ConfigData(String driver, String user, String password, String host, int port, String database,
      String dbTableName) {
  }
}