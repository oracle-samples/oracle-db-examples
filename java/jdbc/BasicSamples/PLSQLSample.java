/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This sample demonstrates the usage of PL/SQL Stored Procedures and Functions in JDBC.
 * 
 * Each unit of this sample demonstrates the following:
 *   1. creating a PL/SQL Stored Procedure/Function,
 *   2. invoking the Stored Procedure/Function with IN, OUT, IN OUT parameters, 
 *   3. and the correspondence of IN/OUT parameter with get/set/register methods.
 *
 * It is required that applications have Oracle JDBC driver jar (ojdbc8.jar) in
 * the class-path, and that the database back end supports SQL (this sample uses
 * an Oracle Database).
 * 
 * To run the sample, you must provide non-default and working values for ALL 3
 * of user, password, and URL. This can be done by either updating
 * this file directly or supplying the 3 values as command-line options
 * and user input. The password is read from console or standard input.
 * java PLSQL2 -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.CallableStatement;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.Types;

import oracle.jdbc.pool.OracleDataSource;

public class PLSQLSample {
  
  private final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  private final static String DEFAULT_USER = "myuser";
  private final static String DEFAULT_PASSWORD = "mypassword";
  //You must provide non-default values for ALL 3 to execute the program
  private static String url = DEFAULT_URL;
  private static String user = DEFAULT_USER;
  private static String password = DEFAULT_PASSWORD;
  private static final String TABLE_NAME = "PLSQL_JDBC_SAMPLE";

  public static void main(String args[]) throws Exception {
    Util.getRealUserPasswordUrl(args);
    
    PLSQLSample sample = new PLSQLSample();
    sample.run();
  }

  private void run() {
    try (Connection conn = getConnection()) {

      // Initialize the table
      init(conn);

      // Demonstrate how a no arg PLSQL procedure can be invoked.
      demoPlsqlProcedureNoParams(conn);

      // Demonstrate how a PLSQL procedure with IN parameters can be invoked.
      demoPlsqlProcedureINParams(conn);

      // Demonstrate how a PLSQL procedure with OUT parameters can be invoked.
      demoPlsqlProcedureOUTParams(conn);

      // Demonstrate how a PLSQL procedure with IN OUT parameters can be invoked.
      demoPlsqlProcedureINOUTParams(conn);

      // Demonstrate how a no arg PLSQL function can be invoked.
      demoPlsqlFunctionNoParams(conn);

      // Demonstrate how a PLSQL function with IN parameters can be invoked.
      demoPlsqlFunctionINParams(conn);

      // Demonstrate how a PLSQL function with OUT parameters can be invoked.
      demoPlsqlFunctionOUTParams(conn);

      // Demonstrate how a PLSQL function with IN OUT parameters can be invoked.
      demoPlsqlFunctionINOUTParams(conn);

      // Cleanup the database after the demo.
      truncateTable(conn);
    } catch (SQLException sqlEx) {
      Util.showError("run", sqlEx);
    }
  }

  private void init(Connection conn) throws SQLException {

    // Truncate the table.
    truncateTable(conn);

    // Load the table with few rows.
    loadTable(conn);
  }
  
  private void loadTable(Connection conn) throws SQLException {
    String insertDml = "INSERT INTO "+TABLE_NAME+" (NUM, NAME, INSERTEDBY) VALUES (?,?,?)";    
    try (PreparedStatement prepStmt = conn.prepareStatement(insertDml)) {
      prepStmt.setInt(1, 1);
      prepStmt.setString(2, "ONE");
      prepStmt.setString(3, "default");
      prepStmt.addBatch();
      
      prepStmt.setInt(1, 2);
      prepStmt.setString(2, "TWO");
      prepStmt.setString(3, "default");
      prepStmt.addBatch();
      
      prepStmt.setInt(1, 3);
      prepStmt.setString(2, "THREE");
      prepStmt.setString(3, "default");
      prepStmt.addBatch();
      
      prepStmt.setInt(1, 4);
      prepStmt.setString(2, "FOUR");
      prepStmt.setString(3, "default");
      prepStmt.addBatch();
      
      prepStmt.executeBatch();
    }
    
    // Display initial set of rows loaded into the table.
    Util.show("Table '"+TABLE_NAME+"' is loaded with: ");
    displayRows(conn, "default");
  }
  
  private void truncateTable(Connection conn) {
    String sql = "TRUNCATE TABLE " + TABLE_NAME;
    Util.show(sql);
    Util.trySql(conn, sql);
  }

  private void demoPlsqlProcedureNoParams(Connection conn) throws SQLException {
    // Create a PLSQL stored procedure that takes no arguments.
    final String PROC_NAME = "ProcNoParams";
    String sql = "CREATE OR REPLACE PROCEDURE "+PROC_NAME+" IS "
                  + "BEGIN "
                  + "INSERT INTO "+TABLE_NAME+" VALUES (5, 'FIVE', '"+PROC_NAME+"'); "
                  + "INSERT INTO "+TABLE_NAME+" VALUES (6, 'SIX', '"+PROC_NAME+"'); "
                  + "INSERT INTO "+TABLE_NAME+" VALUES (7, 'SEVEN', '"+PROC_NAME+"'); "
                  + "INSERT INTO "+TABLE_NAME+" VALUES (8, 'EIGHT', '"+PROC_NAME+"'); "
                + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the stored procedure.
    sql = "CALL "+PROC_NAME+"()";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.execute();
      
      // Display rows inserted by the above stored procedure call.
      Util.show("Rows inserted by the stored procedure '"+PROC_NAME+"' are: ");
      displayRows(conn, PROC_NAME);
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlProcedureNoArgs", sqlEx);
    } finally {
      // Drop the procedure when done with it.
      Util.doSql(conn, "DROP PROCEDURE "+PROC_NAME);
    }
  }
  
  private void demoPlsqlProcedureINParams(Connection conn) throws SQLException {
    // Create a PLSQL stored procedure with IN parameters.
    final String PROC_NAME = "ProcINParams";
    String sql = "CREATE OR REPLACE PROCEDURE "+PROC_NAME+"(num IN NUMBER, name IN VARCHAR2, insertedBy IN VARCHAR2) IS "
        + "BEGIN "
        + "INSERT INTO "+TABLE_NAME+" VALUES (num, name, insertedBy); "
      + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the stored procedure.
    sql = "CALL "+PROC_NAME+"(?,?,?)";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.setInt(1, 9);
      callStmt.setString(2, "NINE");
      callStmt.setString(3, PROC_NAME);
      callStmt.addBatch();
      
      callStmt.setInt(1, 10);
      callStmt.setString(2, "TEN");
      callStmt.setString(3, PROC_NAME);
      callStmt.addBatch();
      
      callStmt.setInt(1, 11);
      callStmt.setString(2, "ELEVEN");
      callStmt.setString(3, PROC_NAME);
      callStmt.addBatch();
      
      callStmt.setInt(1, 12);
      callStmt.setString(2, "TWELVE");
      callStmt.setString(3, PROC_NAME);
      callStmt.addBatch();
      
      callStmt.executeBatch();
      
      // Display rows inserted by the above stored procedure call.
      Util.show("Rows inserted by the stored procedure '"+PROC_NAME+"' are: ");
      displayRows(conn, PROC_NAME);
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlProcedureINParams", sqlEx);
    } finally {
      // Drop the procedure when done with it.
      Util.doSql(conn, "DROP PROCEDURE "+PROC_NAME);
    }
  }
  
  private void demoPlsqlProcedureOUTParams(Connection conn) throws SQLException {
    // Create a PLSQL stored procedure with OUT parameters.
    final String PROC_NAME = "ProcOUTParams";
    String sql = "CREATE OR REPLACE PROCEDURE "+PROC_NAME+"(num IN NUMBER, name IN VARCHAR2, insertedBy IN VARCHAR2, numInserted OUT NUMBER) IS "
        + "BEGIN "
        + "INSERT INTO "+TABLE_NAME+" VALUES (num, name, insertedBy); "
        + "numInserted := num; "
      + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the stored procedure.
    sql = "CALL "+PROC_NAME+"(?,?,?,?)";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.setInt(1, 13);
      callStmt.setString(2, "THIRTEEN");
      callStmt.setString(3, PROC_NAME);
      callStmt.registerOutParameter(4, Types.INTEGER);
      callStmt.execute();
      
      // Display rows inserted by the above stored procedure call.
      Util.show("Rows inserted by the stored procedure '"+PROC_NAME+"' are: ");
      displayRows(conn, PROC_NAME);
      
      // Show the value of OUT parameter after the stored procedure call.
      Util.show("The out parameter value of stored procedure '"+PROC_NAME+"' returned "+callStmt.getInt(4)+".");
      
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlProcedureOUTParams", sqlEx);
    } finally {
      // Drop the procedure when done with it.
      Util.doSql(conn, "DROP PROCEDURE "+PROC_NAME);
    }
  }
  
  private void demoPlsqlProcedureINOUTParams(Connection conn) throws SQLException {
    // Create a PLSQL stored procedure with IN OUT parameters.
    final String PROC_NAME = "ProcINOUTParams";
    String sql = "CREATE OR REPLACE PROCEDURE "+PROC_NAME+"(num IN OUT NUMBER, name IN OUT VARCHAR2, insertedBy IN VARCHAR2) IS "
        + "BEGIN "
        + "INSERT INTO "+TABLE_NAME+" VALUES (num, name, insertedBy); "
        + "num := 0; "
        + "name := 'ZERO'; "
      + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the stored procedure.
    sql = "CALL "+PROC_NAME+"(?,?,?)";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.setInt(1, 14);
      callStmt.registerOutParameter(1, Types.INTEGER);
      
      callStmt.setString(2, "FOURTEEN");
      callStmt.registerOutParameter(2, Types.VARCHAR);
      
      callStmt.setString(3, PROC_NAME);
      callStmt.execute();
      
      // Display rows inserted by the above stored procedure call.
      Util.show("Rows inserted by the stored procedure '"+PROC_NAME+"' are: ");
      displayRows(conn, PROC_NAME);
      
      // Show the values of OUT parameters after the stored procedure call.
      Util.show("Out parameter values of stored procedure '" + PROC_NAME + "': num = " + callStmt.getInt(1)
          + ", name = " + callStmt.getString(2) + ".");
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlProcedureINOUTParams", sqlEx);
    } finally {
      // Drop the procedure when done with it.
      Util.doSql(conn, "DROP PROCEDURE "+PROC_NAME);
    }
  }
  
  private void demoPlsqlFunctionNoParams(Connection conn) throws SQLException {
    // Create a PLSQL function that takes no arguments.
    final String FUNC_NAME = "FuncNoParams";
    String sql = "CREATE OR REPLACE FUNCTION "+FUNC_NAME+" RETURN NUMBER IS "
        + "BEGIN "
        + "INSERT INTO "+TABLE_NAME+" VALUES (15, 'FIFTEEN', '"+FUNC_NAME+"'); "
        + "INSERT INTO "+TABLE_NAME+" VALUES (16, 'SIXTEEN', '"+FUNC_NAME+"'); "
        + "INSERT INTO "+TABLE_NAME+" VALUES (17, 'SEVENTEEN', '"+FUNC_NAME+"'); "
        + "INSERT INTO "+TABLE_NAME+" VALUES (18, 'EIGHTEEN', '"+FUNC_NAME+"'); "
        + "RETURN 4;"   // Return number of row inserted into the table.
      + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the PLSQL function.
    sql = "BEGIN ? := "+FUNC_NAME+"; end;";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.registerOutParameter (1, Types.INTEGER);
      callStmt.execute();
      
      // Display rows inserted by the above PLSQL function call.
      Util.show("Rows inserted by the PLSQL function '"+FUNC_NAME+"' are: ");
      displayRows(conn, FUNC_NAME);
      
      // Show the value returned by the PLSQL function.
      Util.show("The value returned by the PLSQL function '"+FUNC_NAME+"' is "+callStmt.getInt(1)+".");
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlFunctionNoParams", sqlEx);
    } finally {
      // Drop the function when done with it.
      Util.doSql(conn, "DROP FUNCTION "+FUNC_NAME);
    }
  }
  
  private void demoPlsqlFunctionINParams(Connection conn) throws SQLException {
    // Create a PLSQL function with IN parameters.
    final String FUNC_NAME = "FuncINParams";
    String sql = "CREATE OR REPLACE FUNCTION "+FUNC_NAME+"(num IN NUMBER, name IN VARCHAR2, insertedBy IN VARCHAR2) RETURN NUMBER IS "
        + "BEGIN "
        + "INSERT INTO "+TABLE_NAME+" VALUES (num, name, insertedBy); "
        + "RETURN 1;"   // Return number of row inserted into the table.
      + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the PLSQL function.
    sql = "BEGIN ? := "+FUNC_NAME+"(?,?,?); end;";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.registerOutParameter (1, Types.INTEGER);
      callStmt.setInt(2, 19);
      callStmt.setString(3, "NINETEEN");
      callStmt.setString(4, FUNC_NAME);
      callStmt.execute();
      
      // Display rows inserted by the above PLSQL function call.
      Util.show("Rows inserted by the PLSQL function '"+FUNC_NAME+"' are: ");
      displayRows(conn, FUNC_NAME);
      
      // Show the value returned by the PLSQL function.
      Util.show("The value returned by the PLSQL function '"+FUNC_NAME+"' is "+callStmt.getInt(1)+".");
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlFunctionINParams", sqlEx);
    } finally {
      // Drop the function when done with it.
      Util.doSql(conn, "DROP FUNCTION "+FUNC_NAME);
    }
  }
  
  private void demoPlsqlFunctionOUTParams(Connection conn) throws SQLException {
    // Create a PLSQL function with IN parameters.
    final String FUNC_NAME = "FuncOUTParams";
    String sql = "CREATE OR REPLACE FUNCTION "+FUNC_NAME+"(num IN NUMBER, name IN VARCHAR2, insertedBy IN VARCHAR2, numInserted OUT NUMBER) RETURN NUMBER IS "
        + "BEGIN "
        + "INSERT INTO "+TABLE_NAME+" VALUES (num, name, insertedBy); "
        + "numInserted := num; "
        + "RETURN 1;"   // Return number of row inserted into the table.
      + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the PLSQL function.
    sql = "BEGIN ? := "+FUNC_NAME+"(?,?,?,?); end;";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.registerOutParameter (1, Types.INTEGER);
      callStmt.setInt(2, 20);
      callStmt.setString(3, "TWENTY");
      callStmt.setString(4, FUNC_NAME);
      callStmt.registerOutParameter(5, Types.INTEGER);
      callStmt.execute();
      
      // Display rows inserted by the above PLSQL function call.
      Util.show("Rows inserted by the PLSQL function '"+FUNC_NAME+"' are: ");
      displayRows(conn, FUNC_NAME);
      
      // Show the value returned by the PLSQL function.
      Util.show("The value returned by the PLSQL function '"+FUNC_NAME+"' is "+callStmt.getInt(1)+".");
      
      // Show the values of OUT parameters after the PLSQL function call.
      Util.show("Out parameter value of PLSQL function '" + FUNC_NAME + "': num = " + callStmt.getInt(5) + ".");
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlFunctionOUTParams", sqlEx);
    } finally {
      // Drop the function when done with it.
      Util.doSql(conn, "DROP FUNCTION "+FUNC_NAME);
    }
  }
  
  private void demoPlsqlFunctionINOUTParams(Connection conn) throws SQLException {
    // Create a PLSQL function with IN OUT parameters.
    final String FUNC_NAME = "FuncINOUTParams";
    String sql = "CREATE OR REPLACE FUNCTION "+FUNC_NAME+"(num IN OUT NUMBER, name IN OUT VARCHAR2, insertedBy IN VARCHAR2) RETURN NUMBER IS "
        + "BEGIN "
        + "INSERT INTO "+TABLE_NAME+" VALUES (num, name, insertedBy); "
        + "num := 0; "
        + "name := 'ZERO'; "
        + "RETURN 1;"   // Return number of row inserted into the table.
      + "END; ";
    Util.show(sql);
    Util.doSql(conn, sql);
    
    // Invoke the PLSQL function.
    sql = "BEGIN ? := "+FUNC_NAME+"(?,?,?); end;";
    try (CallableStatement callStmt = conn.prepareCall(sql)) {
      callStmt.registerOutParameter (1, Types.INTEGER);
      
      callStmt.registerOutParameter (2, Types.INTEGER);
      callStmt.setInt(2, 20);
      
      callStmt.registerOutParameter (3, Types.VARCHAR);
      callStmt.setString(3, "TWENTY");
      
      callStmt.setString(4, FUNC_NAME);
      callStmt.execute();
      
      // Display rows inserted by the above PLSQL function call.
      Util.show("Rows inserted by the PLSQL function '"+FUNC_NAME+"' are: ");
      displayRows(conn, FUNC_NAME);
      
      // Show the value returned by the PLSQL function.
      Util.show("The value returned by the PLSQL function '"+FUNC_NAME+"' is "+callStmt.getInt(1)+".");
      
      // Show the values of OUT parameters after the PLSQL function call.
      Util.show("Out parameter values of PLSQL function '" + FUNC_NAME + "': num = " + callStmt.getInt(2)
          + ", name = " + callStmt.getString(3) + ".");
    } catch (SQLException sqlEx) {
      Util.showError("demoPlsqlFunctionINOUTParams", sqlEx);
    } finally {
      // Drop the function when done with it.
      Util.doSql(conn, "DROP FUNCTION "+FUNC_NAME);
    }
  }
  
  private void displayRows(Connection conn, String insertedByBind) throws SQLException {
    
    String sql = "SELECT * FROM "+TABLE_NAME+" WHERE insertedBy = ?";
    try (PreparedStatement prepStmt = conn.prepareStatement(sql)) {
      prepStmt.setString(1, insertedByBind);
      
      ResultSet rs = prepStmt.executeQuery();
      while (rs.next()) {
        Util.show(rs.getInt(1)+"\t"+rs.getString(2)+"\t"+rs.getString(3));
      }
    }
  }

  // Get a connection using the driver data source.
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

    public static void trySql(Connection conn, String sql) {
      try (Statement stmt = conn.createStatement()) {
        stmt.execute(sql);
      } catch (SQLException e) {
        // Ignore the exception.
      }
    }

    public static void doSql(Connection conn, String sql) throws SQLException {
      try (Statement stmt = conn.createStatement()) {
        stmt.execute(sql);
      }
    }

  }

}

