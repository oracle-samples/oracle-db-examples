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
import java.util.concurrent.SubmissionPublisher;
import java.util.stream.IntStream;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import oracle.jdbc.OracleStatement;

public class SQLStatementWithAsynchronousJDBC {

  public static void main(String[] args) throws InterruptedException {
    SQLStatementWithAsynchronousJDBC asyncSQL = new SQLStatementWithAsynchronousJDBC();
    try (OracleConnection conn = DatabaseConfig.getConnection()) {
      asyncSQL.createTable(conn);
      IntStream.rangeClosed(0, 3).forEach(i -> asyncSQL.insertData(conn, i, "Java " + i, "Duke " + i));
      asyncSQL.readData(conn);
      Thread.sleep(5000);
      asyncSQL.dropTable(conn);
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }

  private Flow.Publisher<Boolean> insertData(OracleConnection connection, int id, String firstName, String lastName) {
    try {
      final OraclePreparedStatement insertStatement = (OraclePreparedStatement) connection
          .prepareStatement("INSERT INTO employee_names (id, first_name, last_name) VALUES (?, ?, ?)");
      insertStatement.setInt(1, id);
      insertStatement.setString(2, firstName);
      insertStatement.setString(3, lastName);

      Flow.Publisher<Boolean> insertPublisher = insertStatement.unwrap(OraclePreparedStatement.class)
          .executeAsyncOracle();

      insertPublisher.subscribe(new Flow.Subscriber<Boolean>() {
        private Flow.Subscription subscription;

        public void onSubscribe(Flow.Subscription subscription) {
          this.subscription = subscription;
          subscription.request(1L);
        }

        public void onNext(Boolean item) {
        }

        public void onError(Throwable throwable) {
          closeStatement();
          throwable.printStackTrace();
        }

        public void onComplete() {
          closeStatement();
        }

        void closeStatement() {
          try {
            if (insertStatement != null && !insertStatement.isClosed()) {
              insertStatement.close();
            }
          } catch (SQLException closeException) {
            closeException.printStackTrace();
          }
        }
      });

      return insertPublisher;
    } catch (SQLException e) {
      e.printStackTrace();
      SubmissionPublisher<Boolean> publisher = new SubmissionPublisher<>();
      publisher.close();
      return publisher;
    }
  }

  public Flow.Publisher<OracleResultSet> readData(OracleConnection connection) {
    try {
      final OraclePreparedStatement readStatement = (OraclePreparedStatement) connection
          .prepareStatement("SELECT * FROM employee_names WHERE first_name LIKE ?");
      readStatement.setString(1, "Jav%");

      Flow.Publisher<OracleResultSet> readPublisher = readStatement.unwrap(OraclePreparedStatement.class)
          .executeQueryAsyncOracle();

      readPublisher.subscribe(new Flow.Subscriber<OracleResultSet>() {
        private Flow.Subscription subscription;

        public void onSubscribe(Flow.Subscription subscription) {
          this.subscription = subscription;
          subscription.request(Long.MAX_VALUE);
        }

        public void onNext(OracleResultSet resultSet) {
          try {
            while (resultSet.next()) {
              int id = resultSet.getInt("id");
              String firstName = resultSet.getString("first_name");
              String lastName = resultSet.getString("last_name");
              System.out.println("ID: " + id + ", First Name: " + firstName + ", Last Name: " + lastName);
            }
            System.out.println("Finished receiving stream data successfully. \nPreparing to drop table...");
          } catch (SQLException e) {
            onError(e);
          }
        }

        public void onError(Throwable throwable) {
          closeStatement();
          throwable.printStackTrace();
        }

        public void onComplete() {
          closeStatement();
        }

        void closeStatement() {
          try {
            if (readStatement != null && !readStatement.isClosed()) {
              readStatement.close();
            }
          } catch (SQLException closeException) {
            closeException.printStackTrace();
          }
        }
      });
      return readPublisher;
    } catch (SQLException e) {
      e.printStackTrace();
      SubmissionPublisher<OracleResultSet> publisher = new SubmissionPublisher<>();
      publisher.close();
      return publisher;
    }
  }

  private void createTable(OracleConnection connection) {
    String createTableSQL = "CREATE TABLE employee_names (id NUMBER PRIMARY KEY, first_name VARCHAR2(50), last_name VARCHAR2(50))";
    try (OracleStatement createTableStatement = (OracleStatement) connection.createStatement()) {
      createTableStatement.execute(createTableSQL);
      System.out.println("Table 'employee_names' created successfully.");
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }

  private void dropTable(OracleConnection connection) {
    String dropTableSQL = "DROP TABLE employee_names";
    try (OracleStatement dropTableStatement = (OracleStatement) connection.createStatement()) {
      dropTableStatement.execute(dropTableSQL);
      System.out.println("Table 'employee_names' dropped successfully.");
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
}
