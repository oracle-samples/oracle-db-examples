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

import java.sql.Connection;
import java.sql.DatabaseMetaData;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.time.Duration;
import java.time.Instant;
import java.util.Properties;
import java.util.stream.IntStream;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class VirtualThreadsOracleJdbc {

	private final static String DB_URL = DatabaseConfig.getDbUrl();
	private final static String DB_USER = DatabaseConfig.getDbUser();
	private final static String DB_PASSWORD = DatabaseConfig.getDbPassword();
	private static String queryStatement = "SELECT * FROM SH.CUSTOMERS WHERE CUST_ID = 49671";

	public static void main(String args[]) throws SQLException {

		Properties info = new Properties();
		info.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, DB_USER);
		info.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, DB_PASSWORD);
		info.put(OracleConnection.CONNECTION_PROPERTY_FAN_ENABLED, false);
		OracleDataSource ods = new OracleDataSource();
		ods.setURL(DB_URL);
		ods.setConnectionProperties(info);

		OracleConnection connection = (OracleConnection) ods.getConnection();
		DatabaseMetaData dbmd = connection.getMetaData();
		System.out.println("Driver Name: " + dbmd.getDriverName());
		System.out.println("Driver Version: " + dbmd.getDriverVersion());
		System.out.println();

		Instant start = Instant.now();

		// virtual threads
		var threads = IntStream.range(0, 1_500).mapToObj(i -> Thread.startVirtualThread(() -> {
			try {
				doSQLWork(connection, queryStatement);
				System.out.println("Query #: " + (i));
			} catch (SQLException ex) {
				ex.printStackTrace();
			}
		})).toList();

		for (var thread : threads) {
			try {
				thread.join();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}

		Instant finish = Instant.now();
		long timeElapsed = Duration.between(start, finish).getSeconds();
		System.out.println("Elapsed: " + timeElapsed);

	}

	private static void doSQLWork(Connection conn, String queryStatement) throws SQLException {
		conn.setAutoCommit(false);
		try (Statement statement = conn.createStatement();
				ResultSet resultSet = statement.executeQuery(queryStatement)) {
			while (resultSet.next()) {
				System.out.println(new StringBuilder(resultSet.getString(1)).append(" ").append(resultSet.getString(2))
						.append(" ").append(resultSet.getString(3)).append(" ").append(resultSet.getString(4))
						.append(" ").append(resultSet.getInt(5)).toString());
			}
			statement.close();
			resultSet.close();
		}
	}

}