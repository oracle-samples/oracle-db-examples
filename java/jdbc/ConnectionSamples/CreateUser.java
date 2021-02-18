/* Copyright (c) 2021, Oracle and/or its affiliates. All rights reserved.
Licensed under the Universal Permissive License v 1.0 
as shown at http://oss.oracle.com/licenses/upl
*/

/*
 DESCRIPTION
 The code sample creates a new database user and grants the required privileges. 
 (a) Edit this file and update the connection URL along with the admin username and password. 
 (b) Also, provide a new database user and password that you want to create. 
 
 NOTES  Use JDK 1.8 and above  
 
 MODIFIED    (MM/DD/YY)
 nbsundar    02/17/21 - Creation (Contributor - kmensah)
 */
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;

public class CreateUser {
  // The following connection string is pointing to Oracle XE database. 
  // Change this URL to match your target database (Oracle XE or else).
  final static String DB_URL="jdbc:oracle:thin:@//localhost:1521/XEPDB1";
  // Enter the database admin user
  // It is usually "sys as sysdba" for Oracle XE database. 
  final static String AdminUSER = "<DBAdminUser>";
  // Enter the password for the admin user 
  final static String AdminPASSWORD = "<DBAdminPassword>";
  
  // Enter the new database user that you want to create
  final static String newDBUser = "<db-new-username>";
  // Enter the password for the new database user that you want to create
  final static String newDBPassword = "<db-new-password>";
  final static String CONN_FACTORY_CLASS_NAME="oracle.jdbc.pool.OracleDataSource";
  
  /*
   * Sample to create a new database user and password and grant the required privileges.
   * Requirement: database connection string, admin user and admin password 
   */
  public static void main(String args[]) throws Exception {
    // Get the PoolDataSource for UCP
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    // Set the connection factory 
    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS_NAME);
   
    pds.setURL(DB_URL);
    pds.setUser(AdminUSER);
    pds.setPassword(AdminPASSWORD);
    pds.setConnectionPoolName("JDBC_UCP_POOL");
    
    // Create a new database user along with granting the required privileges. 
    String createUserSQL = "BEGIN " +
    "EXECUTE IMMEDIATE ('CREATE USER " + newDBUser + " IDENTIFIED BY " + newDBPassword + 
    " DEFAULT TABLESPACE USERS QUOTA UNLIMITED ON USERS'); " +
    "EXECUTE IMMEDIATE ('GRANT CREATE SESSION, CREATE VIEW, CREATE SEQUENCE, " + 
    " CREATE PROCEDURE, CREATE TABLE, CREATE TRIGGER, CREATE TYPE, " + 
    " CREATE MATERIALIZED VIEW TO " + newDBUser + "'); " +
    "END;";
   
    // Set the connection pool properties
    pds.setInitialPoolSize(5);
    pds.setMinPoolSize(5);
    pds.setMaxPoolSize(20);
    pds.setTimeoutCheckInterval(5);
    pds.setInactiveConnectionTimeout(10);

    // Get the database connection from UCP.
    try (Connection conn = pds.getConnection()) {
      conn.setAutoCommit(false);
      // Prepare a statement to execute the SQL Statement.
      Statement statement = conn.createStatement();
      // Create a new database user and grant privileges
      statement.executeUpdate(createUserSQL);
      System.out.println("New Database user " + newDBUser + " created");
    } catch (SQLException e) {
      System.out.println("CreateUser - "
          + "CreateUser - SQLException occurred : " + e.getMessage());
    }
  } // End of main
} // End of CreateUser



  

    
