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
import java.util.Arrays;
import java.util.Properties;

import oracle.jdbc.OracleType;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class OracleAIVectorSearchWithJava {

  private final static String URL = "jdbc:oracle:thin:@localhost:1521/FREEPDB1";
  private final static String USERNAME = System.getenv("DB_23AI_USERNAME");
  private final static String PASSWORD = System.getenv("DB_23AI_PASSWORD");

  private String insertSql = "INSERT INTO ORACLE_AI_VECTOR_SEARCH_DEMO (VECTOR_DATA) VALUES (?)";
  private String querySql = "SELECT ID, VECTOR_DATA FROM ORACLE_AI_VECTOR_SEARCH_DEMO";
  private String querySqlWithBind = "SELECT ID, VECTOR_DATA FROM ORACLE_AI_VECTOR_SEARCH_DEMO ORDER BY VECTOR_DISTANCE(VECTOR_DATA, ?, COSINE)";

  public static void main(String[] args) throws SQLException {
    OracleAIVectorSearchWithJava oracleAIVectorSearch = new OracleAIVectorSearchWithJava();
    oracleAIVectorSearch.execute();
  }

  private void execute() throws SQLException {

    System.out.println("Starting JDBC connection with PooledDataSource...");
    try (Connection conn = getConnectionFromPooledDataSource()) {
      System.out.println("Connected to Oracle Database 23ai! " + "\n");

      System.out
          .println("Inserting VECTOR with oracle.jdbc.OracleType.VECTOR...");
      insertVector(conn);
      System.out.println(
          "VECTOR with oracle.jdbc.OracleType.VECTOR inserted!" + "\n");

      System.out
          .println("Inserting VECTOR with oracle.jdbc.OracleType.VARCHAR2...");
      insertVectorWithVarChar2(conn);
      System.out.println(
          "VECTOR with oracle.jdbc.OracleType.VARCHAR2 inserted!" + "\n");

      System.out.println("Inserting VECTOR with Batch API...");
      insertVectorWithBatchAPI(conn);
      System.out.println("VECTOR with Batch API inserted!" + "\n");

      System.out.println("Retrieving VECTOR as double array...");
      retrieveVectorAsArray(conn);
      System.out.println("VECTOR retrieved!" + "\n");

      System.out.println("Retrieving VECTOR as String...");
      retrieveVectorAsString(conn);
      System.out.println("VECTOR retrieved!" + "\n");

      System.out.println(
          "Retrieving VECTOR with bound VECTOR (L2 - Euclidean distance)...");
      retrieveVectorWithBoundVector(conn);
      System.out.println("VECTOR retrieved!");

    }
  }

  private void insertVector(Connection connection) throws SQLException {
    PreparedStatement insertStatement = connection.prepareStatement(insertSql,
        new String[]{"ID"});
    float[] vector = {1.1f, 2.2f, 3.3f};
    System.out.println("SQL DML: " + insertSql);
    System.out.println("VECTOR to be inserted: " + Arrays.toString(vector));
    insertStatement.setObject(1, vector, OracleType.VECTOR_FLOAT64);
    insertStatement.executeUpdate();
  }

  private void insertVectorWithVarChar2(Connection connection)
      throws SQLException {
    PreparedStatement insertStatement = connection.prepareStatement(insertSql,
        new String[]{"ID"});
    float[] vector = {1.1f, 2.2f, 3.3f};
    System.out.println("SQL DML: " + insertSql);
    System.out.println("VECTOR to be inserted: " + Arrays.toString(vector));
    insertStatement.setObject(1, Arrays.toString(vector), OracleType.VARCHAR2);
    insertStatement.executeUpdate();
  }

  private void insertVectorWithBatchAPI(Connection connection)
      throws SQLException {

    float[][] vectors = {{1.1f, 2.2f, 3.3f}, {1.3f, 7.2f, 4.3f},
        {5.9f, 5.2f, 7.3f}};
    System.out.println("SQL DML: " + insertSql);
    System.out.println("VECTORs to be inserted as a batch: "
        + Arrays.toString(vectors[0]) + ", " + Arrays.toString(vectors[1])
        + ", " + Arrays.toString(vectors[2]));
    try (PreparedStatement insertStatement = connection
        .prepareStatement(insertSql, new String[]{"ID"})) {
      for (float[] vector : vectors) {
        insertStatement.setObject(1, vector, OracleType.VECTOR_FLOAT64);
        insertStatement.addBatch();
      }
      insertStatement.executeBatch();
    }
  }

  private void retrieveVectorAsArray(Connection connection)
      throws SQLException {
    PreparedStatement queryStatement = connection.prepareStatement(querySql);
    System.out.println("SQL DML: " + querySql);
    ResultSet resultSet = queryStatement.executeQuery();
    float[] vector = null;
    while (resultSet.next()) {
      vector = resultSet.getObject(2, float[].class);
    }
    System.out.println("Retrieved VECTOR: " + Arrays.toString(vector));
  }

  private void retrieveVectorAsString(Connection connection)
      throws SQLException {
    PreparedStatement queryStatement = connection.prepareStatement(querySql);
    System.out.println("SQL DML: " + querySql);
    ResultSet resultSet = queryStatement.executeQuery();
    String vector = null;
    while (resultSet.next()) {
      vector = (String) resultSet.getObject(2);
    }
    System.out.println("Retrieved VECTOR: " + vector);
  }

  private void retrieveVectorWithBoundVector(Connection connection)
      throws SQLException {
    PreparedStatement queryStatement = connection
        .prepareStatement(querySqlWithBind);
    float[] inputVector = {1.0f, 2.2f, 3.3f};
    System.out.println("SQL DML: " + querySqlWithBind);
    System.out.println("Bound VECTOR: " + Arrays.toString(inputVector));
    queryStatement.setObject(1, inputVector, OracleType.VECTOR_FLOAT64);
    ResultSet resultSet = queryStatement.executeQuery();
    resultSet.next();
    float[] outputVector = resultSet.getObject(2, float[].class);
    System.out.println("Retrieved VECTOR: " + Arrays.toString(outputVector));
  }

  private Connection getConnectionFromPooledDataSource() throws SQLException {
    // Create pool-enabled data source instance
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    // set connection properties on the data source
    pds.setConnectionFactoryClassName("oracle.jdbc.pool.OracleDataSource");
    pds.setURL(URL);
    pds.setUser(USERNAME);
    pds.setPassword(PASSWORD);
    // Configure pool properties with a Properties instance
    Properties prop = new Properties();
    prop.setProperty("oracle.jdbc.vectorDefaultGetObjectType", "String");
    pds.setConnectionProperties(prop);
    // Override any pool properties directly
    pds.setInitialPoolSize(10);
    // Get a database connection from the pool-enabled data source
    Connection conn = pds.getConnection();
    return conn;
  }

}
