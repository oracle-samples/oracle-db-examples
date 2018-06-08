/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
   DESCRIPTION
   
    REF CURSOR as INPUT parameter sample.
    This capability was added in the JDBC thin driver in 18c.
    To run the sample, you must enter the DB user's password from the 
    console, and optionally specify the DB user and/or connect URL on 
    the command-line. You can also modify these values in this file 
    and recompile the code. 
      java RefCursorInSample -l <url> -u <user> 
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.jdbc.OracleTypes;
import oracle.jdbc.pool.OracleDataSource;
import oracle.jdbc.OracleCallableStatement;

public class RefCursorInSample {
  
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";

  // You must provide non-default values for all 3 parameters to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  // Connection object for REF CURSOR as INPUT parameter.
  // The sample uses only one connection for all REF CURSOR
  // operations in this demo program.
  private Connection conn;
  
  // Package name used in this sample
  private final String PACKAGE_NAME = "REF_CURSOR_IN_JDBC_SAMPLE";

  // Function names used in this sample
  private final String FUNCTION_NAME1 = "GET_EMP_CURSOR";
  private final String FUNCTION_NAME2 = "NAVIGATE_EMP_CURSOR";
  
  
  /**
   * Entry point of the sample.
   * 
   * @param args
   *          Command line arguments. Supported command line options: -l <url>
   *          -u <user>
   * @throws Exception
   */
  public static void main(String args[]) throws Exception {
    RefCursorInSample refCursorSample = new RefCursorInSample();

    getRealUserPasswordUrl(args);

    // Get a connection and initialize the schema.
    refCursorSample.setup();
    
    // Shows REF CURSOR IN with setCursor() call
    refCursorSample.setCursorSample();

    // Drop table and disconnect from the database.
    refCursorSample.cleanup();
  }
  
  // Gets connection to the database and create a stored procedure.
  void setup() throws SQLException {
    conn = getConnection();
    createFunctions();
  }
  
  // Drop the stored procedure and disconnect from the database
  void cleanup() throws SQLException {
    if (conn != null) {
      dropFunctions();
      conn.close();
      conn = null;
    }
  }
  
  // Shows how to use REF CURSOR IN with setCursor() call
  void setCursorSample() throws SQLException {
    
    show("======== setCursor Sample ========");
    
    // Prepare a PL/SQL call to get a REF CURSOR as an output
    try ( CallableStatement call1 =
      conn.prepareCall ("{ ? = call " + PACKAGE_NAME + "." + FUNCTION_NAME1 + "() }")) {
      call1.registerOutParameter (1, OracleTypes.CURSOR);
      call1.execute ();
      try (ResultSet rset = (ResultSet)call1.getObject (1) ) {
        
        // Dump the first row from the cursor
        show("Fetch first row of a ref cursor in Java:");
        if(rset.next ())
          show(rset.getString ("EMPNO") + "  "
                              + rset.getString ("ENAME"));
        
        // Prepare a PL/SQL call to set a REF CURSOR as an input
        try ( CallableStatement call2 =
          conn.prepareCall ("{ ? = call " + PACKAGE_NAME + "." + FUNCTION_NAME2 + "(?) }")) {
          
          call2.registerOutParameter (1, OracleTypes.INTEGER);
          ((OracleCallableStatement)call2).setCursor(2, rset);
          call2.execute ();
          
          int empno = call2.getInt(1);
          
          show("Fetch second row of the ref cursor in PL/SQL: empno=" + empno);
          
          // Dump the rest of the cursor
          show("Fetch rest of the ref cursor rows in Java:");
          while (rset.next ())
            show(rset.getString ("EMPNO") + "  "
                + rset.getString ("ENAME"));
          
        } // call2
      } // rset
    } // call1
  }
  
  // ==============================Utility Methods==============================

  private void createFunctions() throws SQLException {
    try (Statement stmt = conn.createStatement()) {
      String sql = "CREATE OR REPLACE PACKAGE " + PACKAGE_NAME + " AS " +
                    " TYPE mycursortype IS REF CURSOR RETURN EMP%ROWTYPE; " +
                    " FUNCTION " + FUNCTION_NAME1 + " RETURN mycursortype; " +
                    " FUNCTION " + FUNCTION_NAME2 + " (mycursor mycursortype) RETURN NUMBER; " +
                    "END " + PACKAGE_NAME + ";";
      
      stmt.execute (sql);
      
      sql = "CREATE OR REPLACE PACKAGE BODY " +  PACKAGE_NAME + " AS " +
             " FUNCTION " +  FUNCTION_NAME1 + " RETURN mycursortype IS " +
             "   rc mycursortype; " +
             " BEGIN " +
             "   OPEN rc FOR SELECT * FROM emp ORDER BY empno;" +
             "   RETURN rc; " +
             "  END " + FUNCTION_NAME1 + "; " +
             "       " +
             " FUNCTION " +  FUNCTION_NAME2 + " (mycursor mycursortype) RETURN NUMBER IS " +
             "   rc NUMBER; " +
             "   myrecord EMP%ROWTYPE;" +
             " BEGIN " +
             "   FETCH mycursor INTO myrecord;" +
             "   rc := myrecord.EMPNO;" +
             "   RETURN rc; " +
             "  END " + FUNCTION_NAME2 + "; " +
             "       " +
             "END " + PACKAGE_NAME + ";";
      
      stmt.execute (sql);
    }
  }

  private void dropFunctions() throws SQLException {
    try (Statement stmt = conn.createStatement()) {
      stmt.execute ("DROP PACKAGE " + PACKAGE_NAME);
    }
  }
  
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
      shownln(prompt);
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
  private static void shownln(String msg) {
    System.out.print(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.out.println(msg + " hit error: " + exc.getMessage());
  }
}
