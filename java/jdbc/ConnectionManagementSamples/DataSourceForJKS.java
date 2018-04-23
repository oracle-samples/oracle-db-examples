/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION    
   The code sample shows how to use the DataSource API to establish a connection
   to the Database. You can specify properties with "setConnectionProperties".
   This is the recommended way to create connections to the Database.
   Note that an instance of oracle.jdbc.pool.OracleDataSource doesn't provide
   any connection pooling. It's just a connection factory. A connection pool,
   such as Universal Connection Pool (UCP), can be configured to use an
   instance of oracle.jdbc.pool.OracleDataSource to create connections and 
   then cache them.
    
    Step 1: Enter the Database details in this file. 
            DB_USER, DB_PASSWORD and DB_URL are required
    Step 2: Run the sample with "ant DataSourceForJKS"
  
   NOTES
    Use JDK 1.7 and above
   MODIFIED    (MM/DD/YY)
    nbsundar    02/17/15 - Creation 
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

public class DataSourceForJKS {  
  // Connection string has a "dbaccess" as TNS alias for the connection
  // present in tnsnames.ora. Set the TNS_ADMIN property 
  // to point to the location of tnsnames.ora 
  final static String DB_URL= "jdbc:oracle:thin:@dbaccess";
  final static String DB_USER = "myuser";
  final static String DB_PASSWORD = "mypassword";

 /*
  * The method gets a database connection using 
  * oracle.jdbc.pool.OracleDataSource. It also sets some connection 
  * level properties, such as,
  * OracleConnection.CONNECTION_PROPERTY_DEFAULT_ROW_PREFETCH,
  * OracleConnection.CONNECTION_PROPERTY_THIN_NET_CHECKSUM_TYPES, etc.,
  * There are many other connection related properties. Refer to 
  * the OracleConnection interface to find more. 
  */
  public static void main(String args[]) throws SQLException {
    Properties info = new Properties();     
    info.put(OracleConnection.CONNECTION_PROPERTY_USER_NAME, DB_USER);
    info.put(OracleConnection.CONNECTION_PROPERTY_PASSWORD, DB_PASSWORD);  
    // Set the SSL related connection properties 
    info.put(OracleConnection.CONNECTION_PROPERTY_THIN_SSL_SERVER_DN_MATCH,"true");
    info.put(OracleConnection.CONNECTION_PROPERTY_TNS_ADMIN,"/home/user/cloud");
    info.put(OracleConnection.CONNECTION_PROPERTY_THIN_SSL_VERSION,"1.2");
    // Set the JKS related connection properties
    info.put(OracleConnection.CONNECTION_PROPERTY_THIN_JAVAX_NET_SSL_KEYSTORE,
      "/home/user/cloud/keystore.jks");
    info.put(OracleConnection.CONNECTION_PROPERTY_THIN_JAVAX_NET_SSL_KEYSTOREPASSWORD,"Welcome1");         info.put(OracleConnection.CONNECTION_PROPERTY_THIN_JAVAX_NET_SSL_TRUSTSTORE,
      "/home/user/cloud/truststore.jks");    
    info.put(OracleConnection.CONNECTION_PROPERTY_THIN_JAVAX_NET_SSL_TRUSTSTOREPASSWORD,"Welcome1");      
    OracleDataSource ods = new OracleDataSource();
    ods.setURL(DB_URL);    
    ods.setConnectionProperties(info);

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
      printEmployees(connection);
    }   
  }
 /*
  * Displays first_name and last_name from the employees table.
  */
  public static void printEmployees(Connection connection) throws SQLException {
    // Statement and ResultSet are AutoCloseable and closed automatically. 
    try (Statement statement = connection.createStatement()) {      
      try (ResultSet resultSet = statement
          .executeQuery("select sysdate from dual")) {
        while (resultSet.next())
          System.out.println("Today's date is " + resultSet.getString(1));
               
      }
    }   
  } 
}
