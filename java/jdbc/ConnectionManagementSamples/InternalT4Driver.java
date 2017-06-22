/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION
   The server side Type 4 driver (T4S) is used for code that runs in database 
   session and needs access to another session either on
   the same RDBMS instance/server or on a remote RDBMS instance/server.
 
   Step 1: Connect to SQLPLUS using the database USER/PASSWORD. 
           Make sure to have InternalT4Driver.sql accessible on the 
           client side to execute. 
   Step 2: Run the SQL file after connecting to DB "@InternalT4Driver.sql" 

   NOTES
    Use JDK 1.6 and above
 
   MODIFIED    (MM/DD/YY)
    nbsundar    03/31/15 - Creation (kmensah - Contributor)
 */

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.jdbc.driver.OracleDriver;
import oracle.jdbc.pool.OracleDataSource;

public class InternalT4Driver { 
 /*
  * Demonstrates how to get a standard JDBC connection from 
  * Java running within the database.   
  */
  static public void jrun() throws SQLException {
    // For testing InternalT4Driver
    test("jdbc:oracle:thin:hr/hr@(DESCRIPTION=(ADDRESS=(PROTOCOL=tcp) "
      +"(HOST=localhost)(PORT=5521))(CONNECT_DATA="
    +"(SERVICE_NAME=proddbcluster)))"); 
  }
  
 /*
  * Gets a database connection and prints information from 
  * employees table 
  */
  static public void test(String url) throws SQLException {
    Connection connection = null;
    try {
      System.out.println("Connecting to URL " + url);
      // Using OracleDataSource
      OracleDataSource ods = new OracleDataSource();
      ods.setURL(url);
      connection = ods.getConnection();
      System.out.println("Getting Default Connection "
          + "using OracleDataSource");
      printEmployees(connection);
    }
    finally {
      if (connection != null) connection.close();
    }
    
  }

 /*
  * Displays employee_id and first_name from the employees table.
  */
  static public void printEmployees(Connection connection) throws SQLException {
    ResultSet resultSet = null;
    Statement statement = null;
    try {
      statement = connection.createStatement();
      resultSet = statement.executeQuery("SELECT employee_id, first_name FROM "+ 
                "employees order by employee_id");
      while (resultSet.next()) {
        System.out.println("Emp no: " + resultSet.getInt(1) + "   Emp name: "
            + resultSet.getString(2));
      }
    } catch (SQLException ea) {
      System.out.println("Error during execution: " + ea);
      ea.printStackTrace();
    } finally {
      if (resultSet != null) resultSet.close();
      if (statement != null) statement.close();
    }
  }
}


