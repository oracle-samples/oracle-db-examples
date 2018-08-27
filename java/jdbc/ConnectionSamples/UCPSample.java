/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/

/*
 DESCRIPTION
 The code sample demonstrates Universal Connection Pool (UCP) as a client
 side connection pool and does the following.    
 (a)Set the connection factory class name to 
 oracle.jdbc.pool.OracleDataSource before getting a connection.   
 (b)Set the driver connection properties(e.g.,defaultNChar,includeSynonyms).
 (c)Set the connection pool properties(e.g.,minPoolSize, maxPoolSize). 
 (d)Get the connection and perform some database operations.     

 Step 1: Enter the Database details in DBConfig.properties file. 
 USER, PASSWORD, UCP_CONNFACTORY and URL are required.                   
 Step 2: Run the sample with "ant UCPSample"

 NOTES
 Use JDK 1.7 and above  

 MODIFIED    (MM/DD/YY)
 nbsundar    02/13/15 - Creation (Contributor - tzhou)
 */
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;

public class UCPSample {
  final static String DB_URL="jdbc:oracle:thin:@myhost:1521/orclservicename";
  // Use the TNS Alias name along with the TNS_ADMIN - For ATP and ADW
  // final static String DB_URL="jdbc:oracle:thin:@myhost:1521@wallet_dbname?TNS_ADMIN=/Users/nbsundar/DBCloudService/wallet_JDBCTEST";
  final static String DB_USER = "hr";
  final static String DB_PASSWORD = "hr";
  final static String CONN_FACTORY_CLASS_NAME="oracle.jdbc.pool.OracleDataSource";

  /*
   * The sample demonstrates UCP as client side connection pool.
   */
  public static void main(String args[]) throws Exception {
    // Get the PoolDataSource for UCP
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();

    // Set the connection factory first before all other properties
    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS_NAME);
    pds.setURL(DB_URL);
    pds.setUser(DB_USER);
    pds.setPassword(DB_PASSWORD);
    pds.setConnectionPoolName("JDBC_UCP_POOL");

    // Default is 0. Set the initial number of connections to be created
    // when UCP is started.
    pds.setInitialPoolSize(5);

    // Default is 0. Set the minimum number of connections
    // that is maintained by UCP at runtime.
    pds.setMinPoolSize(5);

    // Default is Integer.MAX_VALUE (2147483647). Set the maximum number of
    // connections allowed on the connection pool.
    pds.setMaxPoolSize(20);

    // Default is 30secs. Set the frequency ineconds to enforce the timeout
    // properties. Applies to inactiveConnectionTimeout(int secs),
    // AbandonedConnectionTimeout(secs)& TimeToLiveConnectionTimeout(int secs).
    // Range of valid values is 0 to Integer.MAX_VALUE. .
    pds.setTimeoutCheckInterval(5);

    // Default is 0. Set the maximum time, in seconds, that a
    // connection remains available in the connection pool.
    pds.setInactiveConnectionTimeout(10);

    // Get the database connection from UCP.
    try (Connection conn = pds.getConnection()) {
      System.out.println("Available connections after checkout: "
          + pds.getAvailableConnectionsCount());
      System.out.println("Borrowed connections after checkout: "
          + pds.getBorrowedConnectionsCount());
      // Perform a database operation
      doSQLWork(conn);
    }
    catch (SQLException e) {
      System.out.println("UCPSample - " + "SQLException occurred : "
          + e.getMessage());
    }
    System.out.println("Available connections after checkin: "
        + pds.getAvailableConnectionsCount());
    System.out.println("Borrowed connections after checkin: "
        + pds.getBorrowedConnectionsCount());
  }

  /*
   * Creates an EMP table and does an insert, update and select operations on
   * the new table created.
   */
  public static void doSQLWork(Connection conn) {
    try {
      conn.setAutoCommit(false);
      // Prepare a statement to execute the SQL Queries.
      Statement statement = conn.createStatement();
      // Create table EMP
      statement.executeUpdate("create table EMP(EMPLOYEEID NUMBER,"
          + "EMPLOYEENAME VARCHAR2 (20))");
      System.out.println("New table EMP is created");
      // Insert some records into the table EMP
      statement.executeUpdate("insert into EMP values(1, 'Jennifer Jones')");
      statement.executeUpdate("insert into EMP values(2, 'Alex Debouir')");
      System.out.println("Two records are inserted.");

      // Update a record on EMP table.
      statement.executeUpdate("update EMP set EMPLOYEENAME='Alex Deborie'"
          + " where EMPLOYEEID=2");
      System.out.println("One record is updated.");

      // Verify the table EMP
      ResultSet resultSet = statement.executeQuery("select * from EMP");
      System.out.println("\nNew table EMP contains:");
      System.out.println("EMPLOYEEID" + " " + "EMPLOYEENAME");
      System.out.println("--------------------------");
      while (resultSet.next()) {
        System.out.println(resultSet.getInt(1) + " " + resultSet.getString(2));
      }
      System.out.println("\nSuccessfully tested a connection from UCP");
    }
    catch (SQLException e) {
      System.out.println("UCPSample - "
          + "doSQLWork()- SQLException occurred : " + e.getMessage());
    }
    finally {
      // Clean-up after everything
      try (Statement statement = conn.createStatement()) {
        statement.execute("drop table EMP");
      }
      catch (SQLException e) {
        System.out.println("UCPSample - "
            + "doSQLWork()- SQLException occurred : " + e.getMessage());
      }
    }
  }
}
