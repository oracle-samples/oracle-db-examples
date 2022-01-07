
/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION    
   The code sample shows how to use the JDBC driver to establish a connection
   to the Autonomous Database (ADB) using database token 
   issued by the OCI Identity service. 

   You need to use either JDBC driver to use
   database token authenticatio. 
    
    Step 1: Enter the DB_URL to pointing to your Autonomous Database (ADB)
    Step 2: Make sure to have either 21.4.0.0.1 or 19.13.0.0.1 JDBC driver 
    in the classpath. 
    Step 2: Compile and Run the sample JDBCDBTokenSample
  
   NOTES
    Use JDK 1.7 and above
   MODIFIED    (MM/DD/YY)
    nbsundar    1/7/21 - Creation 
 */

import java.io.IOException;
import java.io.InputStream;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Properties;

import oracle.jdbc.pool.OracleDataSource;
import oracle.jdbc.OracleConnection;
import java.sql.DatabaseMetaData;

public class JDBCDBTokenSample {  

  //If mutual TLS (mTLS) is enabled then, ADB connection requires wallets. 
  // Download the wallet zip file and provide the path to the zip file as TNS_ADMIN 
  // Note that you need to pass the property oracle.jdbc.tokenAuthentication=OCI_TOKEN for token authentication 
  final static String DB_URL="jdbc:oracle:thin:@dbname_high?TNS_ADMIN=/Users/user/wallet/Wallet_dbname&oracle.jdbc.tokenAuthentication=OCI_TOKEN";
  // If mutla TLS(mTLS) is disabled then, ADB connection does not require wallets. 
  // Copy the connection string from "DB Connection" tab from "Connection Strings" section choosing "TLS" in the dropdown
  //final static String DB_URL="jdbc:oracle:thin:@(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1521)(host=adb.us-phoenix-1.oraclecloud.com))(connect_data=(service_name=gebqqeredfsozhjbqbs_dbname_medium.adb.oraclecloud.com)))?oracle.jdbc.tokenAuthentication=OCI_TOKEN";


  public static void main(String args[]) throws SQLException {

    // For more connection related properties. Refer to 
    // the OracleConnection interface. 
    Properties properties = new Properties();     
        
    properties.put(OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH, "20");    
    properties.put(OracleConnection.CONNECTION_PROPERTY_THIN_NET_CHECKSUM_TYPES, 
          "(MD5,SHA1,SHA256,SHA384,SHA512)");
    properties.put(OracleConnection.CONNECTION_PROPERTY_THIN_NET_CHECKSUM_LEVEL,
          "REQUIRED");
    // Connection property to enable database token authentication.
   // properties.put(OracleConnection.CONNECTION_PROPERTY_TOKEN_AUTHENTICATION, "OCI_TOKEN");


    OracleDataSource ods = new OracleDataSource();
    ods.setURL(DB_URL);    
    ods.setConnectionProperties(properties);

    // With AutoCloseable, the connection is closed automatically.
    try (OracleConnection connection = (OracleConnection) ods.getConnection()) { 
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


  
