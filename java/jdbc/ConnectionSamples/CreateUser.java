/* Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.*/

/*
 DESCRIPTION
 The code sample creates a new database user. 
 (a) Make sure to provide the connection URL and the admin username and password. 
 (b) Provide a new user and password that you want to create. 
 
 NOTES  Use JDK 1.8 and above  
 
 MODIFIED    (MM/DD/YY)
 nbsundar    02/04/21 - Creation (Contributor - kmensah)
 */
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;

public class CreateUser {
  // Update the 
  final static String DB_URL="jdbc:oracle:thin:@//localhost:1521/XEPDB1";
  // Enter the admin database username associated with your XE installation
  // It is usually "sys as sysdba" 
  final static String AdminUSER = "<yourDBUser>";
  // Enter the password for the admin user 
  final static String AdminPASSWORD = "<yourDBPassword>";
  
  
  // Enter the new database user that you want to create
  final static String newDBUser = "<db-new-username>";
  // Enter the password for the new database user that you want to create
  final static String newDBPassword = "<db-new-password>";
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
    
    String createUserSQL = "BEGIN " +
    "EXECUTE IMMEDIATE ('CREATE USER " + newDBUser + " IDENTIFIED BY " + newDBPassword + 
    " DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS'); " +
    "EXECUTE IMMEDIATE ('GRANT CREATE SESSION, CREATE VIEW, CREATE SEQUENCE, " + 
    " CREATE PROCEDURE, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, " + 
    " CREATE MATERIALIZED VIEW TO " + newDBUser + "'); " +
    "END;";

    // Default is 0. Set the initial number of connections to be created
    // when UCP is started.
    pds.setInitialPoolSize(5);

    // Minimum number of connections that is maintained by UCP at runtime
    pds.setMinPoolSize(5);

    // Maximum number of connections allowed on the connection pool
    pds.setMaxPoolSize(20);

    // Get the database connection from UCP.
    try (Connection conn = pds.getConnection()) {
      conn.setAutoCommit(false);
      // Prepare a statement to execute the SQL Queries.
      Statement statement = conn.createStatement();
      // Create a table CUSTOMER
      statement.executeUpdate(createUserSQL);
      System.out.println("New Database user " + newDBUser + " created");
    } catch (SQLException e) {
      System.out.println("QuickStart - "
          + "CreateUser - SQLException occurred : " + e.getMessage());
    }
  } // End of main
} // End of CreateUser



  

    
