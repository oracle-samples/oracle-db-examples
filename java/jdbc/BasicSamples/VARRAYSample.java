/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
   DESCRIPTION

    This code sample demonstrates usage of VARRAY data structure in PL/SQL.
    This capability was added in the JDBC thin driver in 18c.
    To run the sample, you must enter the DB user's password from the 
    console, and optionally specify the DB user and/or connect URL on 
    the command-line. You can also modify these values in this file 
    and recompile the code. 
      java VARRAYSample -l <url> -u <user> 
 */

/*import java.sql.*;
import oracle.sql.*;
import oracle.jdbc.*; */
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.math.BigDecimal;
import java.sql.Array;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.jdbc.OracleArray;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class VARRAYSample {

  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";

  // You must provide non-default values for all 3 parameters to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  // Connection object for VARRAY sample.
  // The sample uses only one connection for all VARRAY
  // operations in this demo program.
  private Connection conn;

  /**
   * Entry point of the sample.
   * 
   * @param args
   *          Command line arguments. Supported command line options: -l <url>
   *          -u <user>
   * @throws Exception
   */
  public static void main(String args[]) throws Exception {
    VARRAYSample vArraySample = new VARRAYSample();

    getRealUserPasswordUrl(args);

    // Get a connection and initialize the schema.
    vArraySample.setup();

    // Shows VARRAY usage
    vArraySample.demoVARRAY();

    // Drop table and disconnect from the database.
    vArraySample.cleanup();
  }

  /**
   * Creates Connection to database and drops the demo table if exists 
   * @throws SQLException
   */
  void setup() throws SQLException {
    conn = getConnection();
    dropTableAndType();
  }


  /**
   * Drop the table, type and close the connection
   * @throws SQLException
   */
  void cleanup() throws SQLException {
    if (conn != null) {
      dropTableAndType();
      conn.close();
      conn = null;
    }
  }



  /**
   * Shows how to use VArray PLSQL collection
   * @throws SQLException
   */
  void demoVARRAY() throws SQLException {

    // Utility method to create table and type required for demo
    createTableAndType();

    demoVARRAYWihtoutBind();

    demoVARRAYWithBind();
  }


  /**
   * Usage of VARRAY with constant object 
   * @throws SQLException
   */
  private void demoVARRAYWihtoutBind() throws SQLException {
    showln("======== demoVARRAYWihtoutBind ========");
    try (Statement stmt = conn.createStatement()) {

      // Insert multiple values of type num_array into single row
      stmt.execute("INSERT INTO varray_table VALUES (num_varray(100, 200))");

      ResultSet rs = stmt.executeQuery("SELECT col1 FROM varray_table");
      showArrayResultSet(rs);
    }
  }

  /**
   * Usage of VARRAY with parametric values
   * @throws SQLException
   */
  private void demoVARRAYWithBind() throws SQLException {
    showln("======== demoVARRAYWithBind =======");
    try (Statement stmt = conn.createStatement()) {

      // Insert a new row with 4 values
      int elements[] = { 300, 400, 500, 600 };
      // Create a new Array with the above elements with given type
      OracleArray newArray = (OracleArray) ((OracleConnection) conn).createOracleArray("NUM_VARRAY", elements);
      // Create prepared statement to insert values
      try (PreparedStatement ps = conn.prepareStatement("INSERT INTO varray_table VALUES (?)")) {
        // Bind the array values to statement
        ps.setArray(1, newArray);
        ps.execute();

        ResultSet rs = stmt.executeQuery("SELECT col1 FROM varray_table");
        showArrayResultSet(rs);
      }
    }
  }

  // ==============================Utility Methods==============================

  /**
   * Creates table with VARRAY type object  
   * @throws SQLException
   */
  private void createTableAndType() throws SQLException {
    try (Statement stmt = conn.createStatement()) {
      // create num_varray with array of elements of type NUMBER
      String sql = "CREATE TYPE num_varray AS VARRAY(10) OF NUMBER(12, 2)";
      stmt.execute(sql);

      // Create table with num_varray with column as VARRAY type
      sql = "CREATE TABLE varray_table (col1 num_varray)";
      stmt.execute(sql);
    }
  }
  
  /**
   * Drop the table and type  
   * @throws SQLException
   */
  private void dropTableAndType() throws SQLException {
    try (Statement stmt = conn.createStatement()) {
      // Drop the table and type if exists
      stmt.execute("DROP TABLE varray_table");
      stmt.execute("DROP TYPE num_varray");
    } catch (SQLException e) {
      // the above drop statements will throw exceptions
      // if the types and tables did not exist before. Just ignore it.
      if (e.getErrorCode() != 942)
        throw new RuntimeException(e);
      else
        showln("INFO: " + e.getMessage());
    }
  }
  
  /**
   * Gets the connection object   
   * @throws SQLException
   */
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
  static String getOptionValue(String args[], String optionName, String defaultVal) {
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

  // Show message line without new line
  private static void showln(String msg) {
    System.out.println(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.out.println(msg + " hit error: " + exc.getMessage());
  }

  /**
   * Display array elements to console.
   * @param rs
   * @throws SQLException
   */
  public static void showArrayResultSet(ResultSet rs) throws SQLException {
    int line = 0;

    while (rs.next()) {
      line++;

      showln("Row " + line + " : ");
      Array array = rs.getArray(1);

      showln("Array is of type " + ((OracleArray) array).getSQLTypeName());
      showln("Array element is of type code " + array.getBaseType());

      showln("Array is of length " + ((OracleArray) array).length());

      // get Array elements
      BigDecimal[] values = (BigDecimal[]) array.getArray();

      for (int i = 0; i < values.length; i++) {
        BigDecimal value = values[i];
        showln(">>Array index " + i + " = " + value.intValue());
      }
    }
  }
}

