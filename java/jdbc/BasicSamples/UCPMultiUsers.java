/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates how JDBC applications use the Oracle
 * Universal Connection Pool (UCP) to pool connections for different
 * users.
 *
 * It is required that applications have both ucp.jar and Oracle JDBC
 * driver jar(s) (such as ojdbc8.jar or ojdbc7.jar) on the classpath,
 * and that the database backend supports SQL (this sample uses an
 * Oracle Database and the default HR schema).
 *
 * To run the sample, you must provide non-default and working values
 * for ALL 3 of user, password, and URL. This can be done by either updating
 * this file directly or supplying the 3 values as command-line options
 * and user input. The password is read from console or standard input.
 *   java UCPMultiUsers -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;


public class UCPMultiUsers {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  // Modify these if user "scott" is locked in DB.
  final static String USER2 = "scott";
  final static String PASSWORD2 = "tiger";

  public static void main(String args[]) throws Exception {
    getRealUserPasswordUrl(args);

    show("\nUCPMultiUsers starts");

    // See sample UCPBasic for basic steps to set up a pool.
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS);
    pds.setURL(url);
    pds.setUser(user);
    pds.setPassword(password);
    pds.setConnectionPoolName("UCPMultiUsers_pool");

    show("Connection pool configured");

    try (Connection conn1 = pds.getConnection()) {
      showPoolStatistics("\nAfter checkout for "+user, pds);

      makeJDBCCalls(conn1);
    } catch (SQLException exc) {
      showError("Checkout with "+user, exc);
    }

    showPoolStatistics("\nAfter checkin for "+user, pds);

    // Use this version of getConnection with different users.
    try (Connection conn2 = pds.getConnection(USER2, PASSWORD2)) {
      showPoolStatistics("\nAfter checkout for "+USER2, pds);

      makeJDBCCalls(conn2);
    } catch (SQLException exc) {
      showError("Checkout with "+USER2, exc);
    }

    showPoolStatistics("\nAfter checkin for "+USER2, pds);

    show("\nUCPMultiUsers completes");
  }

  // Simple query
  static void makeJDBCCalls(Connection conn) {
    try (Statement statement = conn.createStatement()) {
      try (java.sql.ResultSet rset = statement.executeQuery("SELECT USER FROM DUAL")) {
        rset.next();
        show("\n  Current user: " + rset.getString(1));
      }
    } catch (SQLException exc) {
      showError("JDBC operation", exc);
    }
  }

  static void showPoolStatistics(String prompt, PoolDataSource pds)
    throws SQLException {
    show(prompt + " -");
    show("  Available connections: " + pds.getAvailableConnectionsCount());
    show("  Borrowed connections: " + pds.getBorrowedConnectionsCount());
  }

  static void show(String msg) {
    System.out.println(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.err.println(msg + " hit error: " + exc.getMessage());
  }

  static void getRealUserPasswordUrl(String args[]) throws Exception {
    // URL can be modified in file, or taken from command-line
    url  = getOptionValue(args, "-l", DEFAULT_URL);

    // DB user can be modified in file, or taken from command-line
    user = getOptionValue(args, "-u", DEFAULT_USER);

    // DB user's password can be modified in file, or explicitly entered
    readPassword(" Password for " + user + ": ");
  }

  // Get specified option value from command-line.
  static String getOptionValue(
    String args[], String optionName, String defaultVal) {
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

