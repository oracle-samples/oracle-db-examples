/* Copyright (c) 2020, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0 
as shown at http://oss.oracle.com/licenses/upl */

/*
 DESCRIPTION
 The code sample demonstrates establishing a connection to Oracle Autonomous Database using
 Oracle JDBC driver and Universal Connection Pool (UCP). It does the following.  
 
 (a) Set the connection factory class name to 
 oracle.jdbc.pool.OracleDataSource before getting a connection.   
 (b) Set the connection pool properties(e.g.,minPoolSize, maxPoolSize). 
 (c) Get the connection and perform some database operations. 
 For a quick test, the sample retrieves 20 records from the Sales History (SH) schema 
 that is accessible to any DB users on autonomous Database.  
 
 Step 1: Enter the Database details DB_URL and DB_USER. 
 You will need to enter the DB_PASSWORD of your Autonomous Database through console
 while running the sample.  
 Step 2: Download the latest Oracle JDBC driver(ojdbc17.jar) and UCP (ucp17.jar) from Oracle 26ai release. 
 along with oraclepki.jar, osdt_core.jar and osdt_cert.jar and add to your classpath.  
 https://www.oracle.com/database/technologies/appdev/jdbc-downloads.html
 -- For 26ai and 23ai clients: only oraclepki.jar is required in the classpath.
 -- Older versions, 21c or 19c: oraclepki.jar, osdt_core.jar, and osdt_cert.jar are required in the classpath.
 Refer to https://www.oracle.com/database/technologies/maven-central-guide.html               
 Step 3: Compile and Run the sample. 
 
 SH Schema: 
 This sample uses the Sales History (SH) sample schema. SH is a data set suited for 
 online transaction processing operations. The Star Schema Benchmark (SSB) sample schema 
 is available for data warehousing operations. Both schemas are available 
 with your shared ADB instance and do not count towards your storage. 
 ou can use any ADB user account to access these schemas.
 
 NOTES
 Use JDK 1.8 and above 
  
 MODIFIED    (MM/DD/YY)
 nbsundar    11/09/2020 - Creation 
 nbsundar    2/6/2026 - Update 
 */
package com.oracle.jdbctest;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Scanner;

import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;

/*
 * The sample demonstrates connecting to Autonomous Database using 
 * Oracle JDBC driver and UCP as a client side connection pool.
 */
public class ADBQuickStart {  
 
  public static void main(String args[]) throws Exception {
    // Case 1: Use the below URL when Mutual Authentication is enabled and Oracle Wallets are required. 
    // Make sure to have Oracle JDBC driver 18c or above to pass TNS_ADMIN as part of a connection URL.
    // TNS_ADMIN - Should be the path where the client credentials zip (wallet_dbname.zip) file is downloaded 
    // and the required Oracle SSO Wallets are available. 
    // dbname_medium - It is the TNS alias present in tnsnames.ora.
    final String DB_URL="jdbc:oracle:thin:@dbname_medium?TNS_ADMIN=/Users/test/wallet_dbname/";
   
    // Case 2: Use below URL when One-way Authentication is enabled and Oracle Wallets are not required. 
    // Copy the TLS URL from the OCI console by navigating to your Autonomous AI Database Details page 
    // and clicking on Database Connection. Under TLS Authentication, select TLS to copy the connection string for the database. 
    // The connection string looks like the one below. 
    // final String DB_URL="jdbc:oracle:thin:@(description=(retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-phoenix-1.oraclecloud.com))(connect_data(service_name=testservice_jdbctestdb_high.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))";
   
    // Update the Database Username and Password to point to your Autonomous Database
    final String DB_USER = "admin";
    String DB_PASSWORD = "changepassword" ;
    final String CONN_FACTORY_CLASS_NAME="oracle.jdbc.pool.OracleDataSource";
    
    // For security purposes, you must enter the password through the console 
    try {
      Scanner scanner = new Scanner(System.in);
      System.out.print("Enter the password for Autonomous Database: ");
      DB_PASSWORD = scanner.nextLine();
    }
    catch (Exception e) {    
       System.out.println("ADBQuickStart - Exception occurred : " + e.getMessage());
       System.exit(1);
    } 
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


    // Get the database connection from UCP.
    try (Connection conn = pds.getConnection()) {
      System.out.println("Available connections after checkout: "
          + pds.getAvailableConnectionsCount());
      System.out.println("Borrowed connections after checkout: "
          + pds.getBorrowedConnectionsCount());       
      // Perform a database operation
      doSQLWork(conn);
    } catch (SQLException e) {
        System.out.println("ADBQuickStart - "
          + "doSQLWork()- SQLException occurred : " + e.getMessage());
    } 
    
    System.out.println("Available connections after checkin: "
        + pds.getAvailableConnectionsCount());
    System.out.println("Borrowed connections after checkin: "
        + pds.getBorrowedConnectionsCount());
  }
 /*
 * Selects 20 rows from the SH (Sales History) Schema that is the accessible to all 
 * the database users of autonomous database. 
 */
 private static void doSQLWork(Connection conn) throws SQLException {
    String queryStatement = "SELECT CUST_ID, CUST_FIRST_NAME, CUST_LAST_NAME, CUST_CITY," 
      + "CUST_CREDIT_LIMIT FROM SH.CUSTOMERS WHERE ROWNUM < 20 order by CUST_ID";
      
    System.out.println("\n Query is " + queryStatement);
    
    conn.setAutoCommit(false);
    // Prepare a statement to execute the SQL Queries.
    try (Statement statement = conn.createStatement(); 
      // Select 20 rows from the CUSTOMERS table from SH schema. 
      ResultSet resultSet = statement.executeQuery(queryStatement)) {
        System.out.println(String.join(" ", "\nCUST_ID", "CUST_FIRST_NAME", 
             "CUST_LAST_NAME", "CUST_CITY", "CUST_CREDIT_LIMIT"));
        System.out.println("-----------------------------------------------------------");
        while (resultSet.next()) {
          System.out.println(resultSet.getString(1) + " " + resultSet.getString(2) + " " +
           resultSet.getString(3)+ " " + resultSet.getString(4) + " " +
           resultSet.getInt(5));
        }
      System.out.println("\nCongratulations! You have successfully used Oracle Autonomous Database\n");
      } 
  } // End of doSQLWork
  
} // End of ADBQuickStart
