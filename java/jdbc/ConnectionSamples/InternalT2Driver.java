/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION
     The server-side Type 2 (T2S) driver (aka KPRB driver) is for Java in the 
     database. Java running in the database session uses the KPRB driver or 
     T2S driver to access data, locally.     
     We furnish the server-side thin JDBC (aka Type 4 server driver) for 
     accessing data in other session in the same database or a remote Oracle 
     database.
     
     Step 1: Connect to SQLPLUS using the database USER/PASSWORD. 
             Make sure to have InternalT2Driver.sql accessible on the 
             client side to execute. 
     Step 2: Run the SQL file after connecting to DB "@InternalT2Driver.sql" 

   NOTES
    Use JDK 1.6 and above

   MODIFIED    (MM/DD/YY)
    nbsundar    03/23/15 - Creation (kmensah - Contributor)
 */
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.jdbc.driver.OracleDriver;
import oracle.jdbc.pool.OracleDataSource;


public class InternalT2Driver {

  static public void jrun() throws SQLException {
    // For testing InternalT2Driver
    // test("jdbc:oracle:kprb:@");
    test("jdbc:default:connection");
  }  
 /*
  * Shows using the server side Type 2 driver a.k.a KPRB driver 
  */ 
 static public void test(String url) throws SQLException {
    Connection connection = null; 
    try {
      System.out.println("Connecting to URL " + url);
      // Method 1: Using OracleDataSource
      OracleDataSource ods = new OracleDataSource();
      ods.setURL(url);
      connection = ods.getConnection();
      System.out.println("Method 1: Getting Default Connection "
          + "using OracleDataSource");
      // Perform database operation
      printEmployees(connection);

      // Method 2: Using defaultConnection() method
      OracleDriver ora = new OracleDriver();
      connection = ora.defaultConnection();
      System.out.println("Method 2: Getting Default Connection "
          + "using OracleDriver");
      // Perform database operation
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
      resultSet = statement.executeQuery("SELECT employee_id, first_name FROM " 
                             +    "employees order by employee_id");
      while (resultSet.next()) {
        System.out.println("Emp no: " + resultSet.getInt(1) + "   Emp name: "
            + resultSet.getString(2));
      }
    }
    catch (SQLException ea) {
      System.out.println("Error during execution: " + ea);
      ea.printStackTrace();
    }
    finally {
      if (resultSet != null) resultSet.close();
      if (statement != null) statement.close();   
    }
  }
}


