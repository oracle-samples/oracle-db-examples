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

import java.sql.SQLException;
import java.util.concurrent.Flow;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.pool.OracleDataSource;

public class SQLStatementWithAsynchronousJDBC {

	private OracleDataSource ods = null;
	private OracleConnection conn = null;

	public SQLStatementWithAsynchronousJDBC() {
		try {
			ods = new OracleDataSource();
			// jdbc:oracle:thin@[hostname]:[port]/[DB service/name]
			ods.setURL("jdbc:oracle:thin@[hostname]:[port]/[DB service/name");
			ods.setUser("[Username]");
			ods.setPassword("[Password]");

			conn = (OracleConnection) ods.getConnection();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	public static void main(String[] args) {
		SQLStatementWithAsynchronousJDBC asyncSQL = new SQLStatementWithAsynchronousJDBC();
		try {
			// Execute a SQL DDL statement to create a database table
			// asynchronously
			asyncSQL.createTable(asyncSQL.getConn());
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	/**
	 * Asynchronously creates a new table by executing a DDL SQL statement
	 * 
	 * @param connection Connection to a database where the table is created
	 * @return A Publisher that emits the result of executing DDL SQL
	 * @throws SQLException If a database access error occurs before the DDL SQL can
	 *                      be executed
	 */
	private Flow.Publisher<Boolean> createTable(OracleConnection connection) throws SQLException {

		OraclePreparedStatement createTableStatement = (OraclePreparedStatement) connection
				.prepareStatement("CREATE TABLE employee_names (" + "id NUMBER PRIMARY KEY, " + "first_name VARCHAR(50), "
						+ "last_name VARCHAR2(50))");

		Flow.Publisher<Boolean> createTablePublisher = createTableStatement.unwrap(OraclePreparedStatement.class)
				.executeAsyncOracle();

		createTablePublisher.subscribe(

				// This subscriber will close the PreparedStatement
				new Flow.Subscriber<Boolean>() {
					public void onSubscribe(Flow.Subscription subscription) {
						subscription.request(1L);
					}

					public void onNext(Boolean item) {
					}

					public void onError(Throwable throwable) {
						closeStatement();
					}

					public void onComplete() {
						closeStatement();
					}

					void closeStatement() {
						try {
							createTableStatement.close();
						} catch (SQLException closeException) {
							closeException.printStackTrace();
							;
						}
					}
				});

		return createTablePublisher;
	}

	public OracleDataSource getOds() {
		return ods;
	}

	public void setOds(OracleDataSource ods) {
		this.ods = ods;
	}

	public OracleConnection getConn() {
		return conn;
	}

	public void setConn(OracleConnection conn) {
		this.conn = conn;
	}

}