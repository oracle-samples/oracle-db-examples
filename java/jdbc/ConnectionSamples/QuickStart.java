/* Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0 
as shown at http://oss.oracle.com/licenses/upl
*/

/*
 DESCRIPTION
 The code sample connects to the Oracle Database and creates a table 'todoitem'. 
 It inserts few records into this table and displays the list of tasks and task completion status. 
 Edit this file and update the connection URL along with the database username and password
 that point to your database. 

 NOTES
 Use JDK 1.8 and above  
 
 MODIFIED    (MM/DD/YY)
 nbsundar    02/17/21 - Creation (Contributor - kmensah)
 */
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import java.util.Properties;

import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;

public class QuickStart {
  // The following connection string is pointing to Oracle XE database. 
  // Change this URL to match your target Oracle database (XE or else)
  final static String DB_URL="jdbc:oracle:thin:@//localhost:1521/XEPDB1";
  // Enter the database user 
  final static String DB_USER = "<db-user>";
  // Enter the database password 
  final static String DB_PASSWORD = "<db-password>";
  final static String CONN_FACTORY_CLASS_NAME="oracle.jdbc.pool.OracleDataSource";

  /*
   * The sample creates a table 'todoitem' that lists tasks and task completion status. 
   * Requirement: database connection string, database user and database password 
   */
  public static void main(String args[]) throws Exception {
  
    // Get the PoolDataSource for UCP
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    // Set the connection factory 
    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS_NAME);
    pds.setURL(DB_URL);
    pds.setUser(DB_USER);
    pds.setPassword(DB_PASSWORD);
    pds.setConnectionPoolName("JDBC_UCP_POOL");

    // Set the connection pool properties
    pds.setInitialPoolSize(5);
    pds.setMinPoolSize(5);
    pds.setMaxPoolSize(20);
    pds.setTimeoutCheckInterval(5);
    pds.setInactiveConnectionTimeout(10);

    // Get the database connection from UCP.
    try (Connection conn = pds.getConnection()) {
      System.out.println("Available connections after checkout: "
          + pds.getAvailableConnectionsCount());
      System.out.println("Borrowed connections after checkout: "
          + pds.getBorrowedConnectionsCount());
      doSQLWork(conn);
    }
    
    System.out.println("Available connections after checkin: "
        + pds.getAvailableConnectionsCount());
    System.out.println("Borrowed connections after checkin: "
        + pds.getBorrowedConnectionsCount());
  }

  /*
   * Creates a 'todoitem' table, insert few rows, and select the data from
   * the table created. Remove the table after verifying the data. 
   */
  public static void doSQLWork(Connection conn) {
    try {
      conn.setAutoCommit(false);
      // Prepare a statement to execute the SQL Statement.
      Statement statement = conn.createStatement();
      
      // Create a table 'todoitem' 
      String createSQL = "CREATE TABLE todoitem " 
      + "(id NUMBER GENERATED ALWAYS AS IDENTITY," 
      + " description VARCHAR2(4000), "
      + " creation_ts TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,"
      + " done NUMBER(1, 0), PRIMARY KEY(id))";

      statement.executeUpdate(createSQL);
      System.out.println("New table 'todoitem' is created");
      
      //Insert sample data
      String[] description = { "Task 1", "Task 2", "Task 3", "Task 4", "Task 5" };
      int[] done = { 0, 0, 1, 0, 1 };
      
      // Insert some records into the table 'todoitem'
      PreparedStatement prepStatement = conn.prepareStatement("INSERT INTO " 
      + " todoitem (description, done) VALUES(?, ?)");
      for(int row = 0; row < description.length; row++) {
        prepStatement.setString(1, description[row]);
        prepStatement.setInt(2, done[row]); 
        prepStatement.addBatch();
      }
      prepStatement.executeBatch();
       
      System.out.println("New records are inserted");
      
      // Verify the data from the table "todoitem"
      ResultSet resultSet = statement.executeQuery("SELECT DESCRIPTION, DONE FROM TODOITEM");
      System.out.println("\nNew table 'todoitem' contains:");
      System.out.println("DESCRIPTION" + "\t" + "DONE");
      System.out.println("--------------------------");
      while (resultSet.next()) {
        System.out.println(resultSet.getString(1) + "\t\t" + resultSet.getInt(2));
      }
      System.out.println("\nSuccessfully tested a connection from UCP");
    }
    catch (SQLException e) {
      System.out.println("QuickStart - "
          + "doSQLWork()- SQLException occurred : " + e.getMessage());
    }
    finally {
      // Clean-up after everything
      try (Statement statement = conn.createStatement()) {
        statement.execute("DROP TABLE TODOITEM");
      }
      catch (SQLException e) {
        System.out.println("QuickStart - "
            + "doSQLWork()- SQLException occurred : " + e.getMessage());
      }
    }
  }
}

    
