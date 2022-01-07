/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION    
   The code sample shows how to use the JDBC driver and UCP to establish a
   connection to the Autonomous Database (ADB) using database token 
   issued by the OCI Identity service. 
    
    Step 1: Enter the DB_URL to pointing to your Autonomous Database (ADB)
    Step 2: Make sure to have either 21.4.0.0.1 or 19.13.0.0.1 JDBC driver 
    and UCP (ucp.jar) in the classpath. Both must be from the same version. 
    Step 2: Compile and Run the sample UCPDBTokenSample
  
   NOTES
    Use JDK8 and above

   MODIFIED    (MM/DD/YY)
    nbsundar    1/7/21 - Creation 
 */

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import java.sql.DatabaseMetaData;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.jdbc.OracleConnection;
import java.sql.DatabaseMetaData;

public class UCPDBTokenSample {
 
  //If mutual TLS (mTLS) is enabled then, ADB connection requires wallets. 
  // Download the wallet zip file and provide the path to the zip file as TNS_ADMIN 
  // Note that you need to pass the property oracle.jdbc.tokenAuthentication=OCI_TOKEN for token authentication 
  final static String DB_URL="jdbc:oracle:thin:@demodb_high?TNS_ADMIN=/Users/nbsundar/ATPTesting/Wallet_DemoDB&oracle.jdbc.tokenAuthentication=OCI_TOKEN";
  
  // If mutla TLS(mTLS) is disabled then, ADB connection does not require wallets. 
  // Copy the connection string from "DB Connection" tab from "Connection Strings" section choosing "TLS" in the dropdown
  //final static String DB_URL="jdbc:oracle:thin:@(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-phoenix-1.oraclecloud.com))(connect_data=(service_name=gebqqvpozhjbqbs_testdb_medium.adb.oraclecloud.com)))?oracle.jdbc.tokenAuthentication=OCI_TOKEN";
 
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

    Properties properties = new Properties();     
        
    properties.put(OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH, "20");    
    properties.put(OracleConnection.CONNECTION_PROPERTY_THIN_NET_CHECKSUM_TYPES, 
          "(MD5,SHA1,SHA256,SHA384,SHA512)");
    properties.put(OracleConnection.CONNECTION_PROPERTY_THIN_NET_CHECKSUM_LEVEL,
          "REQUIRED");
    // Connection property to enable IAM-Authentication 
    properties.put(OracleConnection.CONNECTION_PROPERTY_TOKEN_AUTHENTICATION, "OCI_TOKEN");

    pds.setConnectionProperties(properties);


    // Get the database connection from UCP.
    try (OracleConnection connection = (OracleConnection) pds.getConnection()) {
      // Perform a database operation
      // Get the JDBC driver name and version 
      DatabaseMetaData dbmd = connection.getMetaData();       
      System.out.println("Driver Name: " + dbmd.getDriverName());
      System.out.println("Driver Version: " + dbmd.getDriverVersion());
      // Print some connection properties
      System.out.println("Default Row Prefetch Value is: " + 
         connection.getDefaultRowPrefetch());
      System.out.println("Database Username is: " + connection.getUserName());
      System.out.println();
      // Perform a database operation 
      printTableNames(connection);
    }
  }

  /*
  * Displays 15 table_name from all_tables. 
  */
  public static void printTableNames(Connection connection) throws SQLException {
    // Statement and ResultSet are AutoCloseable and closed automatically. 
    try (Statement statement = connection.createStatement()) {      
      try (ResultSet resultSet = statement
          .executeQuery("select table_name from all_tables where rownum < 15")) {
        System.out.println("Table name");
        System.out.println("---------------------");
        while (resultSet.next())
          System.out.println(resultSet.getString(1));  
      }
    }   
  } 
}

    
