/*
  Copyright (c) 2021, 2022, Oracle and/or its affiliates.

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

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Properties;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class JdbcConnectionToOracleAtpOnOdsa {

	private String url;
	private String databaseUser;
	private String databasePassword;
	private String databaseQueryResults;
	private final String queryStatement = "SELECT CUST_CITY FROM SH.CUSTOMERS WHERE CUST_FIRST_NAME = ? AND CUST_YEAR_OF_BIRTH = ?";

	public JdbcConnectionToOracleAtpOnOdsa() {
		ClassLoader classLoader = getClass().getClassLoader();
		InputStream inputStream = classLoader.getResourceAsStream("config.properties");
		Properties jdbcConnectionProperties = new Properties();
		try {
			jdbcConnectionProperties.load(inputStream);
		} catch (IOException e) {
			e.printStackTrace();
		}
		url = jdbcConnectionProperties.getProperty("DB_URL");
		databaseUser = jdbcConnectionProperties.getProperty("DB_USER");
		databasePassword = jdbcConnectionProperties.getProperty("DB_PASSWORD");
	}

	public String runQuery(String name, int year) throws SQLException {
		Properties info = new Properties();
		info.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, databaseUser);
		info.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, databasePassword);
		info.put(OracleConnection.CONNECTION_PROPERTY_FAN_ENABLED, false);
		OracleDataSource ods = new OracleDataSource();
		ods.setURL(url);
		ods.setConnectionProperties(info);
		OracleConnection connection = (OracleConnection) ods.getConnection();
		DatabaseMetaData dbmd = connection.getMetaData();
		System.out.println("Driver Name: " + dbmd.getDriverName());
		System.out.println("Driver Version: " + dbmd.getDriverVersion());
		System.out.println();
		try {
			databaseQueryResults = doSQLWork(connection, queryStatement, name, year);
		} catch (SQLException ex) {
			ex.printStackTrace();
		}
		return databaseQueryResults;
	}

	private String doSQLWork(Connection conn, String queryStatement, String name, int year) throws SQLException {
		conn.setAutoCommit(false);
		StringBuilder queryResult = new StringBuilder();
		PreparedStatement statement = conn.prepareStatement(queryStatement);
		statement.setString(1, name);
		statement.setInt(2, year);
		ResultSet resultSet = statement.executeQuery();
		while (resultSet.next()) {
			queryResult.append(resultSet.getString(1)).toString();
		}
		statement.close();
		resultSet.close();
		return queryResult.toString();
	}

}