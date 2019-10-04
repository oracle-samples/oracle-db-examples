/* $Header: dbjava/demo/samples/generic/AssociativeArraysSample2.java /main/1 2019/09/06 07:14:40 cmahidha Exp $ */

/* Copyright (c) 2019, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This sample demonstrates the usage of Associative Arrays (Index-By-Tables) in JDBC.
 * Uses composite types (Objects) as elements.
 * 
 * Each unit of this sample demonstrates the following:
 *   1. defining a PL/SQL package that groups Index-By SQL type and a stored procedure,
 *   2. creating an Oracle Array with an array or a map of objects for Index-By type.
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
import java.sql.Struct;
import java.sql.Types;
import java.util.HashMap;
import java.util.Map;

import oracle.jdbc.OracleArray;
import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;

public class AssociativeArraysSample2 {
  private final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  private final static String DEFAULT_USER = "myuser";
  private final static String DEFAULT_PASSWORD = "mypassword";
  // You must provide non-default values for ALL 3 to execute the program
  private static String url = DEFAULT_URL;
  private static String user = DEFAULT_USER;
  private static String password = DEFAULT_PASSWORD;
  
  private static final int NO_OF_RECORDS = 10;
  
  private static String PACKAGE_NAME = "indexbydemopkg";
  private static String RECORD_NAME = "rec";
  private static String INDEX_BY_TYPE_NAME = "indexbytype";
  private static String PROCEDURE_NAME = "proc";

  private static String FULLY_QUALIFIED_RECORD_TYPE_NAME = (PACKAGE_NAME + "." + RECORD_NAME).toUpperCase();
  private static String FULLY_QUALIFIED_INDEX_BY_TYPE_NAME = (PACKAGE_NAME + "." + INDEX_BY_TYPE_NAME).toUpperCase();
  private static String FULLY_QUALIFIED_PROCEDURE_NAME = (PACKAGE_NAME + "." + PROCEDURE_NAME).toUpperCase();

  private static String CREATE_PKG_DDL = 
      "CREATE OR REPLACE PACKAGE "+PACKAGE_NAME+" IS "
          + "\n\tid\tNUMBER(10);"
          + "\n\tname\tVARCHAR2(20);"
          + "\n\tTYPE "+RECORD_NAME+" IS RECORD (p_id "+PACKAGE_NAME+".id%TYPE, p_name "+PACKAGE_NAME+".name%TYPE);"
          + "\n\tTYPE "+INDEX_BY_TYPE_NAME+" IS TABLE OF "+RECORD_NAME+" INDEX BY BINARY_INTEGER;"
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

    AssociativeArraysSample2 sample = new AssociativeArraysSample2();
    sample.run();
  }
  
  private void run() {
    try (Connection conn = getConnection()) {
      // Create PLSQL package in the database.
      createPlSqlPackage(conn);

      // Demonstrates usage of Index-By table and instantiation of
      // java.sql.Array with an array of objects.
      demoIndexByTableUsageWithArrayOfObjects(conn);

      // Demonstrates usage of Index-By tables and instantiation of
      // java.sql.Array with a map of objects.
      demoIndexByTableUsageWithMapOfObjects(conn);

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
   * with an array of objects.
   */
  private void demoIndexByTableUsageWithArrayOfObjects(Connection conn) throws SQLException {
    Struct[] records = new Struct[NO_OF_RECORDS];

    for (int i = 0; i < NO_OF_RECORDS; i++) {
      records[i] = conn.createStruct(FULLY_QUALIFIED_RECORD_TYPE_NAME, new Object[] { i, "name_" + i });
    }

    // Create Oracle Array.
    final Array inParam = ((OracleConnection) conn).createOracleArray(FULLY_QUALIFIED_INDEX_BY_TYPE_NAME, records);

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
  private void demoIndexByTableUsageWithMapOfObjects(Connection conn) throws SQLException {
    int[] indices = new int[] { -10, 20, 10, -20, 40, 45, 33, -15, 15, 18 };
    // Initialize the map. The indices of Associative Array can be sparse and negative.
    final Map<Integer, Struct> map = new HashMap<>();
    for (int i = 0; i < NO_OF_RECORDS; i++) {
      final Struct record = conn.createStruct(FULLY_QUALIFIED_RECORD_TYPE_NAME,
          new Object[] { indices[i], "name_" + indices[i] });
      map.put(indices[i], record);
    }

    // Create Oracle Array.
    final Array inParam = ((OracleConnection) conn).createOracleArray(FULLY_QUALIFIED_INDEX_BY_TYPE_NAME, map);

    // Prepare CallableStatement with stored procedure call SQL and execute.
    try (CallableStatement cStmt = prepareCallAndExecute(conn, inParam);) {
      // Read values of OUT/IN OUT parameter as an array of elements.
      readOutParamsAsArray(cStmt);

      // Read values of OUT/IN OUT parameter as an array of elements.
      readOutParamsAsMap(cStmt);
    }
  }
  
  /**
   * Read values of OUT/IN OUT parameter as an array of elements.
   */
  private void readOutParamsAsArray(CallableStatement cStmt) throws SQLException {
    // Read OUT parameter.
    final Array outParam = cStmt.getArray(2);
    final Object[] outParamArrayOfRecords = (Object[]) outParam.getArray();

    System.out.println("\nValues of OUT param read as an array of objects:");
    for (int i = 0; i < NO_OF_RECORDS; i++) {
      final Struct record = (Struct) outParamArrayOfRecords[i];
      final Object[] attrs = record.getAttributes();
      System.out.print(attrs[0] + "," + attrs[1] + ";\t");
    }

    // Read IN OUT parameter.
    final Array inOutParam = cStmt.getArray(3);
    final Object[] inOutParamArrayOfRecords = (Object[]) inOutParam.getArray();
    System.out.println("\n\nValues of IN OUT param read as an array of Strings:");
    for (int i = 0; i < NO_OF_RECORDS; i++) {
      final Struct record = (Struct) inOutParamArrayOfRecords[i];
      final Object[] attrs = record.getAttributes();
      System.out.print(attrs[0] + "," + attrs[1] + ";\t");
    }
  }
  
  /**
   * Read values of OUT/IN OUT parameter as a Map of objects.
   */
  private void readOutParamsAsMap(CallableStatement cStmt) throws SQLException {
    // Read OUT parameter as Map<Integer, Object>.
    final Array outParam = cStmt.getArray(2);
    @SuppressWarnings("unchecked")
    final Map<Integer, Struct> outParamMap = (Map<Integer, Struct>) ((OracleArray) outParam).getJavaMap();
    System.out.println("\n\nValues of OUT param read as a Map of <Integer, Struct> pairs:");
    for (Map.Entry<Integer, Struct> entry : outParamMap.entrySet()) {
      final Object[] attrs = entry.getValue().getAttributes();
      System.out.println(entry.getKey() + "\t:\t" + attrs[0] + "," + attrs[1]);
    }

    // Read IN OUT parameter as Map<Integer, Object>.
    final Array inOutParam = cStmt.getArray(3);
    @SuppressWarnings("unchecked")
    final Map<Integer, Struct> inOutParamMap = (Map<Integer, Struct>) ((OracleArray) inOutParam).getJavaMap();
    System.out.println("\nValues of IN OUT param read as a Map of <Integer, Struct> pairs:");
    for (Map.Entry<Integer, Struct> entry : inOutParamMap.entrySet()) {
      final Object[] attrs = entry.getValue().getAttributes();
      System.out.println(entry.getKey() + "\t:\t" + attrs[0] + "," + attrs[1]);
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

