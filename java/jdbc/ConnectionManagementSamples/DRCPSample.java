/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION
    The sample code shows how Java applications can connect to the Oracle 
    Database using Database Resident Connection Pool (DRCP) as the server 
    side connection pool which can be shared across multiple middle tiers 
    or clients. DRCP pools database server processes and sessions (the 
    combination is known as a "pooled server").  A Connection Broker manages
    the "pooled servers" in the database instance. Upon a request from
    the client, the connection broker picks the appropriate "pooled server" and
    hands-off the client to that pooled server. The client directly
    communicates with the "pooled server" for all its database activity.  
    The "pooled server" is handed back to the connection broker when the 
    client releases it. 
    
    DRCP can be used with any third party client-side connection pool such as 
    DBCP, C3PO etc.,  Third party client side connection pools must attach and
    detach connections explicitly to the connection broker through 
    attachServerConnection() and detachServerConnection(). They should also 
    set Connection Class as shown in the sample.   
    
    Use-case for DRCP: DRCP should be used in applications when multiple middle
    tiers are connected to the same database, DRCP allows you to share 
    server-side resources between the middle-tier's independent connection
    pools. For more details on DRCP refer to JDBC Developer's guide
    (https://docs.oracle.com/database/121/JJDBC/toc.htm)
    
 
  PRE-REQUISITE: DRCP should be configured at the server side before using DRCP.
  Refer to JDBC Developers Reference Guide for more details. The sample DRCP URL
  shown below refers to the client side configuration of DRCP. 

  Step 1: Enter the Database details in this file. 
          DB_USER, DB_PASSWORD and DRCP_URL are required.
          A Sample DRCP URL is shown below. (server=POOLED) identifies 
          that DRCP is enabled on the server side.           
          DRCP_URL = jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=
          (ADDRESS=(PROTOCOL=tcp)(HOST=proddbcluster)(PORT=5521)))
          (CONNECT_DATA=(SERVICE_NAME=proddb)(server=POOLED)))          
  Step 2: Run the sample with "ant DRCPSample"
  
   NOTES
    Use JDK 1.7 and above

   MODIFIED    (MM/DD/YY)
    nbsundar    03/02/15 - Creation
 */
import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Properties;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;
/*
 * The method shows how to use DRCP when a third party client side connection 
 * pool is used.  Make sure that connection URL used is correct and DRCP is 
 * configured both at the server side and client side. 
 */
public class DRCPSample {
  final static String DRCP_URL= "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(HOST=myhost)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=myorcldbservicename)(server=POOLED)))";
  final static String DB_USER = "hr";
  final static String DB_PASSWORD = "hr";

  static public void main(String args[]) throws SQLException {
    // Create an OracleDataSource instance and set properties
    OracleDataSource ods = new OracleDataSource();
    ods.setUser(DB_USER);
    ods.setPassword(DB_PASSWORD);
    // Make sure to use the correct DRCP URL. Refer to sample DRCP URL.
    ods.setURL(DRCP_URL);
    // "Connection class" allows dedicating a subset of pooled server to
    // a specific application. Several connection classes may be 
    // used for different applications
    Properties connproperty = new Properties();
    connproperty.setProperty("oracle.jdbc.DRCPConnectionClass",
        "DRCP_connect_class");
    ods.setConnectionProperties(connproperty);

    // AutoCloseable: Closes a resource that is no longer needed.
    // With AutoCloseable, the connection is closed automatically.
    try (OracleConnection connection = (OracleConnection) (ods.getConnection())) {
      System.out.println("DRCP enabled: " + connection.isDRCPEnabled());
      // Explicitly attaching the connection before its use
      // Required when the client side connection pool is not UCP
      connection.attachServerConnection();
      // Perform any database operation
      doSQLWork(connection);      
      // Explicitly detaching the connection
      // Required when the client side connection pool is not UCP
      connection.detachServerConnection((String) null);
    }
  }  
 /*
  * Displays system date(sysdate). Shows a simple database operation. 
  */
  public static void doSQLWork(Connection connection) throws SQLException {
    // Statement and ResultSet are AutoCloseable by this syntax
    try (Statement statement = connection.createStatement()) {
      try (ResultSet resultSet = statement
          .executeQuery("select SYSDATE from DUAL")) {
        while (resultSet.next())
          System.out.print("Today's date is " + resultSet.getString(1) + " ");
      }
    }
    System.out.println("\n");
  } 
}


