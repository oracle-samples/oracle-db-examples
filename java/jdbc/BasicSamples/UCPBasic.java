/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates the simple steps of how JDBC applications
 * use the Oracle Universal Connection Pool (UCP).
 *
 * JDBC applications typically interact with UCP via a pool-enabled
 * data source. The embedded connection pool is implicitly created
 * at the first connection borrow (or checkout) from the pool.
 *
 * The basic steps include first creating a pool-enabled data source,
 * configuring properties essential to establishing JDBC connections,
 * and then invoking JDBC APIs to get connections from the data source
 * and the embedded connection pool.
 *
 * For comparison, this sample also illustrates how applications do
 * regular JDBC connect using a JDBC driver data source. It is very
 * simple to migrate JDBC applications to using UCP.
 *
 * It is required that applications have both ucp.jar and Oracle JDBC
 * driver jar(s) (such as ojdbc8.jar or ojdbc7.jar) on the classpath,
 * and that the database backend supports SQL (this sample uses an
 * Oracle Database).
 *
 * To run the sample, you must provide non-default and working values
 * for ALL 3 of user, password, and URL. This can be done by either updating
 * this file directly or supplying the 3 values as command-line options
 * and user input. The password is read from console or standard input.
 *   java UCPBasic -url <url> -user <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

// From Oracle JDBC driver
import oracle.jdbc.pool.OracleDataSource;

import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;


public class UCPBasic {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  public static void main(String args[]) throws Exception {
    UCPBasic sample = new UCPBasic();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  private void run() throws Exception {
    demoRegularJDBCConnect();
    demoUCPConnect();
  }

  // Illustrates how to get a connection using a driver data source.
  private void demoRegularJDBCConnect() {
    show("\ndemoRegularJDBCConnect starts");

    try {
      OracleDataSource ods = new OracleDataSource();
      ods.setURL(url);
      ods.setUser(user);
      ods.setPassword(password);

      // This creates a physical connection to the database.
      Connection conn = ods.getConnection();
      show("Created a physical connection: " + conn);

      // This closes the physical connection.
      conn.close();
      show("Closed physical connection: " + conn);
    } catch (Throwable e) {
      showError("demoRegularJDBCConnect", e);
    }

    show("demoRegularJDBCConnect completes");
  }

  // Illustrates how to use a UCP-enabled data source.
  private void demoUCPConnect() {
    show("\nUCPBasic starts");

    try {
      /*
       * Step 1 - creates a pool-enabled data source instance
       */
      PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();

      /*
       * Step 2 - configures pool properties for establishing connections.
       *          These include required and optional properties.
       */

      /* Required pool properties */

      // UCP uses a connection factory to create physical connections.
      // This is typically a JDBC driver javax.sql.DataSource or
      // java.sql.Driver implementation class.
      pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS);
      pds.setURL(url);
      pds.setUser(user);
      pds.setPassword(password);

      /* Optional pool properties */

      // Pool name should be unique within the same JVM instance.
      // It is useful for administrative tasks, such as starting,
      // stopping, refreshing a pool. Setting a pool name is optional
      // but recommended. If user does not set a pool name, UCP will
      // automatically generate one.
      pds.setConnectionPoolName("UCPBasic_pool");

      // The default is 0.
      pds.setInitialPoolSize(5);

      // The default is 0.
      pds.setMinPoolSize(5);

      // The default is Integer.MAX_VALUE.
      pds.setMaxPoolSize(10);

      show("Connection pool configured");

      /*
       * Step 3 - borrow connections from and return connections to
       *          the connection pool.
       */

      // Borrow a connection from UCP. The connection object is a proxy
      // of a physical connection. The physical connection is returned
      // to the pool when Connection.close() is called on the proxy.
      try (Connection conn1 = pds.getConnection()) {
        showPoolStatistics("After checkout", pds);

        makeJDBCCalls(conn1);
      } catch (SQLException exc) {
        showError("1st checkout", exc);
      }

      showPoolStatistics("After checkin", pds);

      // Another round of borrow/return.
      try (Connection conn2 = pds.getConnection()) {
        showPoolStatistics("After 2nd checkout", pds);

        makeJDBCCalls(conn2);
      } catch (SQLException exc) {
        showError("2nd checkout", exc);
      }

      showPoolStatistics("After 2nd checkin", pds);
    } catch (Throwable e) {
      showError("demoUCPConnect", e);
    }

    show("UCPBasic completes");
  }

  // Simple query
  private void makeJDBCCalls(Connection conn) {
    try (Statement statement = conn.createStatement()) {
      statement.execute("SELECT 1 FROM DUAL");
    } catch (SQLException exc) {
      showError("JDBC operation", exc);
    }
  }

  private void showPoolStatistics(String prompt, PoolDataSource pds)
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
    url  = getOptionValue(args, "-url", DEFAULT_URL);

    // DB user can be modified in file, or taken from command-line
    user = getOptionValue(args, "-user", DEFAULT_USER);

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

