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

import java.sql.CallableStatement;
import java.sql.SQLException;
import java.util.Properties;
import java.util.concurrent.ThreadLocalRandom;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class JDBCStoredProcEmployee {

	private final static String DB_URL = DatabaseConfig.getDbUrl();
	private final static String DB_USER = DatabaseConfig.getDbUser();
	private final static String DB_PASSWORD = DatabaseConfig.getDbPassword();
	private static OracleConnection con;
	private static CallableStatement stmt;

	public static void main(String[] args) {

		System.out.println("--------------------");
		System.out.println("Input parameters");
		System.out.println("--------------------");
		int id = ThreadLocalRandom.current().nextInt();
		System.out.println("ID: " + id);

		String name = "Duke";
		System.out.println("Name: " + name);

		String role = "Mascott";
		System.out.println("Role: " + role);

		String department = "Dev Evangelism";
		System.out.println("Department: " + department);

		String building = "Block A";
		System.out.println("Building: " + building);

		try {

			Properties info = new Properties();
			info.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, DB_USER);
			info.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, DB_PASSWORD);
			info.put(OracleConnection.CONNECTION_PROPERTY_FAN_ENABLED, false);

			// JDBC datasource
			OracleDataSource ods = new OracleDataSource();
			ods.setURL(DB_URL);
			ods.setConnectionProperties(info);

			// JDBC connection
			con = (OracleConnection) ods.getConnection();

			// CallableStatement
			// https://docs.oracle.com/en/java/javase/19/docs/api/java.sql/java/sql/CallableStatement.html
			stmt = con.prepareCall("{call ADMIN.INSERT_EMPLOYEE_PRC(?,?,?,?,?,?)}");

			// set IN parameters
			stmt.setInt(1, id);
			stmt.setString(2, name);
			stmt.setString(3, role);
			stmt.setString(4, department);
			stmt.setString(5, building);

			// register OUT parameter
			stmt.registerOutParameter(6, java.sql.Types.VARCHAR);

			stmt.executeUpdate();

			// get OUT parameter
			String result = stmt.getString(6);

			System.out.println("--------------------\n");
			System.out.println("Output parameter");
			System.out.println("--------------------");
			System.out.println("Procedured executed : " + result);

		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			try {
				stmt.close();
				con.close();
			} catch (SQLException e) {
				e.printStackTrace();
			}
		}
	}

}