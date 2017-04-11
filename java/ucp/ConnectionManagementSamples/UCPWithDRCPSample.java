/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/

/*
   DESCRIPTION
    DRCP should be used in applications where there are multiple middle tiers 
    and the number of active connections in the middle tiers is fairly
    lower than the number of open connections. This sample shows the steps
    involved in accessing a Database using Database Resident Connection 
    Pool(DRCP) as the server side connection pool and Universal Connection 
    Pool(UCP) as the client side connection pool. DRCP features can be 
    optimized by front-ending with a client side pooling mechanism in either 
    middle or client tier.  
    
    The purpose of the client-side pooling mechanism is to maintain liaison
    or attachment to Connection Broker. Client-side connection pools must
    attach and detach connections to the connection broker through 
    attachServerConnection() and detachServerConnection(). The benefit of
    using UCP over third party client pool is that, UCP transparently takes
    care of attaching and detaching server connections.
    
    Step 1: Enter the Database details in this file. 
           DB_USER, DB_PASSWORD and DRCP_URL are required.
           A Sample DRCP URL is shown below.            
           DRCP_URL = jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS_LIST=(ADDRESS=
           (PROTOCOL=tcp)(HOST=proddbcluster)(PORT=25225)))
          (CONNECT_DATA=(SERVICE_NAME=proddb))(server=POOLED))          
    Step 2: Run the sample with "ant UCPWithDRCPSample" 
     
   PRIVATE CLASSES
      None

   NOTES
       Use JDK 1.7 and above

   MODIFIED    (MM/DD/YY)
    nbsundar    02/17/15 - Creation
 */
import java.sql.Connection;
import java.sql.Statement;
import java.sql.ResultSet;
import java.sql.SQLException;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class UCPWithDRCPSample {
  final static String DRCP_URL= "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(HOST=myhost)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=myorcldbservicename)(server=POOLED)))";
  final static String DB_USER = "hr";
  final static String DB_PASSWORD = "hr";
  final static String UCP_CONNFACTORY = "oracle.jdbc.pool.OracleDataSource";
  
 /*
  * The sample shows how to use DRCP with UCP. Make sure that correct  
  * connection URL is used and DRCP is enabled both on the server side 
  * and on the client side. 
  */
  static public void main(String args[]) throws SQLException {
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    pds.setConnectionFactoryClassName(UCP_CONNFACTORY);    
    pds.setUser(DB_USER);
    pds.setPassword(DB_PASSWORD);
    // Make sure that DRCP_URL has (SERVER=POOLED) specified
    pds.setURL(DRCP_URL);
    pds.setConnectionPoolName("DRCP_UCP_Pool");

    // Set UCP Properties
    pds.setInitialPoolSize(1);
    pds.setMinPoolSize(4);
    pds.setMaxPoolSize(20);

    // Get the Database Connection from Universal Connection Pool.
    try (Connection conn = pds.getConnection()) {
      System.out.println("\nConnection obtained from UniversalConnectionPool");
      // Perform a database operation
      doSQLWork(conn);
      System.out.println("Connection returned to the UniversalConnectionPool");
    }
  }

 /*
  * Displays system date (sysdate). 
  */
  public static void doSQLWork(Connection connection) throws SQLException {
    // Statement and ResultSet are auto-closable by this syntax
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



