import java.sql.DriverManager;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.jdbc.pool.OracleDataSource;


/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
   DESCRIPTION
    A very basic Java stored procedure sample. For more complex Java stored procedure samples, 
    please explore https://github.com/oracle/oracle-db-examples/tree/master/java/ojvm directory.
    Java stored procedure in the database executed using the KPRB JDBC driver in the Oracle JVM instance.
    To run the sample:
     1. loadjava -r -v -user jdbcuser/jdbcuser123 JavaStoredProcSample.java
        This loads a java stored procedure in the database.
     2. sqlplus jdbcuser/jdbcuser123 @JavaStoredProcSample.sql
        This script first creates a wrapper stored procedure for the java function.
        This calls java stored procedure from sqlplus and print number of emplyoees in the department number 20.
 */
public class JavaStoredProcSample {
  
  // This stored procedure executes on same client connection/session in the database. 
  // So special JDBC URL use with default connection. 
  final static String DEFAULT_URL_IN_DB = "jdbc:default:connection:";

  // Get the total number of employees for a given department.
  // This method calls from the java stored procedure wrapper
  // define in the JavaStoredProcSample.sql script.
  public static int getEmpCountByDept(int deptNo) {
    int count = 0;
    
    try {
     // Get default connection on the current session from the client
     Connection conn = DriverManager.getConnection(DEFAULT_URL_IN_DB);
     
     count = getEmpCountByDept(conn, deptNo);
    }
    catch(SQLException sqe) {
      showError("getEmpCountByDept", sqe);
    }
  
    // Returns the calculated result value
    return count;
  }

  // Get the total number of employees for a given department.
  // This is a common method call from in database or out of database
  // running of this sample.
  static int getEmpCountByDept(Connection conn, int deptNo) {
    int count = 0;
    
    // Execute a SQL query 
    String sql = "SELECT COUNT(1) FROM EMP WHERE DEPTNO = ?";
     
    // Gets the result value
    try(PreparedStatement pstmt = conn.prepareStatement(sql)) {
      pstmt.setInt(1, deptNo);
      try (ResultSet rs = pstmt.executeQuery()) {
        if (rs.next()) {
          count = rs.getInt(1);
        }
      }
    }
    catch(SQLException sqe) {
      showError("getEmpCountByDept", sqe);
    }
  
    // Returns the calculated result value
    return count;
  }
  
  // Display error message
  static void showError(String msg, Throwable exc) {
    System.out.println(msg + " hit error: " + exc.getMessage());
  }
  
  
  //================ All of the following code only for running this sample out of the database ========================================

  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;
  
  private Connection conn;
  
  
  /**
   * Entry point of the sample for running it out of the database.
   * 
   * @param args
   *          Command line arguments. Supported command line options: -l <url>
   *          -u <user>
   * @throws Exception
   */
  public static void main(String args[]) throws Exception {
    JavaStoredProcSample javaProc = new JavaStoredProcSample();

    getRealUserPasswordUrl(args);

    // Get connection and initialize schema.
    javaProc.setup();
    
    // Call java stored proc out of database run
    int deptNo = 20;
    
    int count = javaProc.getEmpCountByDept(javaProc.conn, deptNo);
    show("" +  count);
    
    // Disconnect from the database.
    javaProc.cleanup();
  }
  
  // Gets connection to the database
  void setup() throws SQLException {
    conn = getConnection();
  }

  // Disconnect from the database
  void cleanup() throws SQLException {
    if (conn != null) {
      conn.close();
      conn = null;
    }
  }
  
  
  // ==============================Utility Methods==============================

  private Connection getConnection() throws SQLException {
    // Create an OracleDataSource instance and set properties
    OracleDataSource ods = new OracleDataSource();
    ods.setUser(user);
    ods.setPassword(password);
    ods.setURL(url);

    return ods.getConnection();
  }

  static void getRealUserPasswordUrl(String args[]) throws Exception {
    // URL can be modified in file, or taken from command-line
    url = getOptionValue(args, "-l", DEFAULT_URL);

    // DB user can be modified in file, or taken from command-line
    user = getOptionValue(args, "-u", DEFAULT_USER);

    // DB user's password can be modified in file, or explicitly entered
    readPassword(" Password for " + user + ": ");
  }

  // Get specified option value from command-line, or use default value
  static String getOptionValue(String args[], String optionName,
      String defaultVal) {
    String argValue = "";

    try {
      int i = 0;
      String arg = "";
      boolean found = false;

      while (i < args.length) {
        arg = args[i++];
        if (arg.equals(optionName)) {
          if (i < args.length)
            argValue = args[i++];
          if (argValue.startsWith("-") || argValue.equals("")) {
            argValue = defaultVal;
          }
          found = true;
        }
      }

      if (!found) {
        argValue = defaultVal;
      }
    } catch (Exception e) {
      showError("getOptionValue", e);
    }
    return argValue;
  }

  static void readPassword(String prompt) throws Exception {
    if (System.console() == null) {
      BufferedReader r = new BufferedReader(new InputStreamReader(System.in));
      showln(prompt);
      password = r.readLine();
    } else {
      char[] pchars = System.console().readPassword("\n[%s]", prompt);
      if (pchars != null) {
        password = new String(pchars);
        java.util.Arrays.fill(pchars, ' ');
      }
    }
  }
  
  private static void show(String msg) {
    System.out.println(msg);
  }

  // Show message line without new line
  private static void showln(String msg) {
    System.out.print(msg);
  }
}
