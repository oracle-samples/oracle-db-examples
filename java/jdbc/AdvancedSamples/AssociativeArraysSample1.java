/* $Header: dbjava/demo/samples/generic/AssociativeArraysSample1.java /main/1 2019/09/06 07:14:40 cmahidha Exp $ */

/* Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This sample demonstrates the usage of Associative Arrays (Index-By-Tables) in JDBC.
 * Uses scalar data types as elements.
 * 
 * Each unit of this sample demonstrates the following:
 *   1. defining a PL/SQL package that groups Index-By SQL type and a stored procedure,
 *   2. creating an Oracle Array with an array or a map of elements for Index-By type.
 *   2. invoking the Stored Procedure with IN, OUT, IN OUT Index-By type parameters, 
 *   3. and the correspondence of IN/OUT parameter with get/set/register methods.
 *
 * It is required that applications have Oracle JDBC driver 18c release (ojdbc8.jar) in
 * the class-path. The previous release of Oracle JDBC drivers provided support only for 
 * PL/SQL Associative Arrays of Scalar data types. Also, the support was restricted only to 
 * the values of the key-value pairs of the Arrays. Oracle Database Release 18c supports
 * accessing both the keys (indexes) and values of Associative Arrays, and also provides
 * support for Associative Arrays of object types.
 * 
 * The following APIs can be used for Index By table types on Oracle database release 
 * version 12c and higher. 
 * 
 * Array createOracleArray(String arrayTypeName,
 *                      Object elements)
 *                      throws SQLException

 * ARRAY createARRAY(String typeName,
 *                 Object elements)
 *                 throws SQLException
 *                 
 * It is recommended to continue using the following deprecated APIs on Oracle database
 * releases earlier than 12c.
 * 
 * oracle.jdbc.OraclePreparedStatement.setPlsqlIndexTable()
 * oracle.jdbc.OracleCallableStatement.getPlsqlIndexTable()
 * oracle.jdbc.OracleCallableStatement.getOraclePlsqlIndexTable()
 * oracle.jdbc.OracleCallableStatement.registerIndexTableOutParameter()
 * 
 * For detailed documentation, refer 4.7 Accessing PL/SQL Associative Arrays in Oracle 
 * Database JDBC Developer's Guide, Release 18c.
 * 
 * To run the sample, you must provide non-default and working values for ALL 3
 * of user, password, and URL. This can be done by either updating
 * this file directly or supplying the 3 values as command-line options
 * and user input. The password is read from console or standard input.
 * java AssociativeArraysSample1 -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Array;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;
import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;
import java.util.stream.Collectors;

import oracle.jdbc.OracleArray;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class AssociativeArraysSample1 {
  private final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  private final static String DEFAULT_USER = "myuser";
  private final static String DEFAULT_PASSWORD = "mypassword";
  // You must provide non-default values for ALL 3 to execute the program
  private static String url = DEFAULT_URL;
  private static String user = DEFAULT_USER;
  private static String password = DEFAULT_PASSWORD;
  
  private static String PACKAGE_NAME = "indexbydemopkg";
  private static String INDEX_BY_TYPE_NAME = "indexbytype";
  private static String PROCEDURE_NAME = "proc";

  private static String FULLY_QUALIFIED_INDEX_BY_TYPE_NAME = (PACKAGE_NAME + "." + INDEX_BY_TYPE_NAME).toUpperCase();
  private static String FULLY_QUALIFIED_PROCEDURE_NAME = (PACKAGE_NAME + "." + PROCEDURE_NAME).toUpperCase();

  private static String CREATE_PKG_DDL = 
      "CREATE OR REPLACE PACKAGE "+PACKAGE_NAME+" IS "
          + "\n\tTYPE "+INDEX_BY_TYPE_NAME+" IS TABLE OF VARCHAR2(40) INDEX BY BINARY_INTEGER;"
          + "\n\tPROCEDURE "+PROCEDURE_NAME+"( "
            + "\n\t\tp_in IN "+INDEX_BY_TYPE_NAME+", "
            + "\n\t\tp_out OUT "+INDEX_BY_TYPE_NAME+", "
            + "\n\t\tp_inout IN OUT "+INDEX_BY_TYPE_NAME
          + "\n\t); "
      + "\nEND "+PACKAGE_NAME+";";
      
  private static String CREATE_PKG_BODY_DDL = 
      "CREATE OR REPLACE PACKAGE BODY "+PACKAGE_NAME+" AS"
          + "\n\tPROCEDURE "+PROCEDURE_NAME+"( "
            + "\n\t\tp_in IN "+INDEX_BY_TYPE_NAME+", "
            + "\n\t\tp_out OUT "+INDEX_BY_TYPE_NAME+", "
            + "\n\t\tp_inout IN OUT "+INDEX_BY_TYPE_NAME
          + "\n\t) IS "
          + "\n\tl_idx BINARY_INTEGER;"
          + "\n\tBEGIN"
            + "\n\t\tl_idx := p_in.FIRST;"
            + "\n\t\tWHILE(l_idx IS NOT NULL)"
            + "\n\t\tLOOP"
              + "\n\t\t\tp_out(l_idx)\t:=\tp_in(l_idx);"
              + "\n\t\t\tp_inout(l_idx)\t:=\tp_in(l_idx);"
              + "\n\t\t\tl_idx := p_in.NEXT(l_idx);"
            + "\n\t\tEND LOOP;"
          + "\n\tEND;"
        + "\nEND;";

  public static void main(String args[]) throws Exception {
    Util.getRealUserPasswordUrl(args);

    AssociativeArraysSample1 sample = new AssociativeArraysSample1();
    sample.run();
  }
  
  private void run() {
    try (Connection conn = getConnection()) {
      // Create PLSQL package in the database.
      createPlSqlPackage(conn);

      // Demonstrates usage of Index-By table and instantiation of
      // java.sql.Array with an array of elements.
      demoIndexByTableWithElementsAsArray(conn);

      // Demonstrates usage of Index-By tables and instantiation of
      // java.sql.Array with a map of elements.
      demoIndexByTableWithElementsAsMapOfEntries(conn);

    } catch (SQLException sqlEx) {
      Util.showError("run", sqlEx);
    }
  }
  
  /**
   * Creates PLSQL package in the database.
   */
  private void createPlSqlPackage(Connection conn) throws SQLException {
    try (Statement stmt = conn.createStatement()) {
      System.out.println("CREATE PACKAGE DDL:\n\n" + CREATE_PKG_DDL + "\n" + CREATE_PKG_BODY_DDL);
      stmt.execute(CREATE_PKG_DDL);
      stmt.execute(CREATE_PKG_BODY_DDL);
    }
  }
  
  /**
   * Demonstrates usage of Index-By table and instantiation of java.sql.Array
   * with an array of elements.
   */
  private void demoIndexByTableWithElementsAsArray(Connection conn) throws SQLException {
    // Initialize an array of strings.
    final String[] inParamArrayOfStrings = { "str1", "str2", "str3str3str3str3str3str3str3str3str3", null, null,
        "str444444444444444444444444444", null, "", "          ", "\n", "    hi           " };

    // Create Oracle Array.
    final Array inParam = ((OracleConnection) conn).createOracleArray(FULLY_QUALIFIED_INDEX_BY_TYPE_NAME,
        inParamArrayOfStrings);

    // Prepare CallableStatement with stored procedure call SQL and execute.
    try (CallableStatement cStmt = prepareCallAndExecute(conn, inParam);) {
      // Read values of OUT/IN OUT parameter as an array of elements.
      readOutParamsAsArray(cStmt);

      // Read values of OUT/IN OUT parameter as an array of elements.
      readOutParamsAsMap(cStmt);
    }
  }
  
  /**
   * Demonstrates usage of Index-By tables and instantiation of java.sql.Array
   * with a map of elements.
   */
  private void demoIndexByTableWithElementsAsMapOfEntries(Connection conn) throws SQLException {
    // Initialize the map. The indices of Associative Array can be sparse and negative.
    final Map<Integer, String> map = new HashMap<>();
    map.put(-10, "str1");
    map.put(20, "str2");
    map.put(-30, "str3str3str3str3str3str3str3str3str3");
    map.put(10, null);
    map.put(-20, null);
    map.put(40, "str444444444444444444444444444");
    map.put(45, null);
    map.put(33, "");
    map.put(-15, "          ");
    map.put(15, "\n");
    map.put(18, "    hi           ");

    // Create Oracle Array.
    final Array inParam = ((OracleConnection) conn).createOracleArray(FULLY_QUALIFIED_INDEX_BY_TYPE_NAME, map);

    // Prepare CallableStatement with stored procedure call SQL and execute.
    try (CallableStatement cStmt = prepareCallAndExecute(conn, inParam)) {
      // Read values of OUT/IN OUT parameter as an array of elements.
      readOutParamsAsArray(cStmt);

      // Read values of OUT/IN OUT parameter as an array of elements.
      readOutParamsAsMap(cStmt);
    }
  }

  /**
   * Prepare CallableStatement with stored procedure call SQL and execute.
   */
  private CallableStatement prepareCallAndExecute(Connection conn, Object elements) throws SQLException {
    final CallableStatement cStmt = conn.prepareCall("BEGIN " + FULLY_QUALIFIED_PROCEDURE_NAME + " (?,?,?); END;");
    cStmt.setObject(1, elements);
    cStmt.registerOutParameter(2, Types.ARRAY, FULLY_QUALIFIED_INDEX_BY_TYPE_NAME);
    cStmt.registerOutParameter(3, Types.ARRAY, FULLY_QUALIFIED_INDEX_BY_TYPE_NAME);
    cStmt.execute();

    return cStmt;
  }
  
  /**
   * Read values of OUT/IN OUT parameter as an array of elements.
   */
  private void readOutParamsAsArray(CallableStatement cStmt) throws SQLException {
    // Read OUT parameter.
    final Array outParam = cStmt.getArray(2);
    final String[] outParamArrayOfStrings = (String[]) outParam.getArray();
    System.out.println("\nValues of OUT param read as an array of Strings:");
    System.out.println(Arrays.stream(outParamArrayOfStrings).collect(Collectors.joining(", ")));

    // Read IN OUT parameter.
    final Array inOutParam = cStmt.getArray(3);
    final String[] inOutParamArrayOfStrings = (String[]) inOutParam.getArray();
    System.out.println("\nValues of IN OUT param read as an array of Strings:");
    System.out.println(Arrays.stream(inOutParamArrayOfStrings).collect(Collectors.joining(", ")));
  }
  
  /**
   * Read values of OUT/IN OUT parameter as a Map of objects.
   */
  private void readOutParamsAsMap(CallableStatement cStmt) throws SQLException {
    // Read OUT parameter as Map<Integer, Object>.
    final Array outParam = cStmt.getArray(2);
    @SuppressWarnings("unchecked")
    final Map<Integer, String> outParamMap = (Map<Integer, String>) ((OracleArray) outParam).getJavaMap();
    System.out.println("\nValues of OUT param read as a Map of <Integer, String> pairs:");
    outParamMap.forEach((key, value) -> {
      System.out.println(key + "\t:\t" + value);
    });

    // Read IN OUT parameter as Map<Integer, Object>.
    final Array inOutParam = cStmt.getArray(3);
    @SuppressWarnings("unchecked")
    final Map<Integer, String> inOutParamMap = (Map<Integer, String>) ((OracleArray) inOutParam).getJavaMap();
    System.out.println("\nValues of IN OUT param read as a Map of <Integer, String> pairs:");
    inOutParamMap.forEach((key, value) -> {
      System.out.println(key + "\t:\t" + value);
    });
  }
  
  /**
   * Get a connection using the driver data source.
   */
  private Connection getConnection() throws SQLException {
    OracleDataSource ods = new OracleDataSource();
    ods.setURL(url);
    ods.setUser(user);
    ods.setPassword(password);

    // Creates a physical connection to the database.
    return ods.getConnection();
  }

  // Utility methods.
  private static class Util {

    static void getRealUserPasswordUrl(String args[]) throws Exception {
      // URL can be modified in file, or taken from command-line
      url = getOptionValue(args, "-l", DEFAULT_URL);

      // DB user can be modified in file, or taken from command-line
      user = getOptionValue(args, "-u", DEFAULT_USER);

      // DB user's password can be modified in file, or explicitly entered
      readPassword("Password for " + user + ": ");
    }

    public static void show(String msg) {
      System.out.println(msg);
    }

    public static void showError(String msg, Throwable exc) {
      System.err.println(msg + " hit error: " + exc.getMessage());
    }

    // Get specified option value from command-line.
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
      if (System.console() != null) {
        char[] pchars = System.console().readPassword("\n[%s]", prompt);
        if (pchars != null) {
          password = new String(pchars);
          java.util.Arrays.fill(pchars, ' ');
        }
      } else {
        BufferedReader r = new BufferedReader(new InputStreamReader(System.in));
        show(prompt);
        password = r.readLine();
      }
    }
    
  }
  
}

