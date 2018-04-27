/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates how applications use the connection harvesting
 * feature of Oracle Universal Connection Pool (UCP).
 *
 * Connection Harvesting allows a specified number of borrowed connections
 * to be reclaimed when the connection pool reaches a specified number of
 * available connections. Least recently used connections are harvested first.
 *
 * This feature helps to ensure that a certain number of connections are
 * always available in the pool to maximize performance.
 *
 * UCP gives applications control over which borrowed connections can be
 * harvested. By default, all connections are harvestable. Applications
 * can use the HarvestableConnection interface to explicitly specify
 * whether a connection is harvestable.
 *
 * For harvestable connections, UCP also provides ConnectionHarvestingCallback
 * that allows applications to perform customized cleanup tasks when
 * connections are harvested by the pool.
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
 *   java UCPHarvesting -url <url> -user <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.ucp.ConnectionHarvestingCallback;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.HarvestableConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;


public class UCPHarvesting {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  public static void main(String args[]) throws Exception {
    UCPHarvesting sample = new UCPHarvesting();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  void run() throws Exception {
    runDefaultAllConnectionsHarvestable();
    runWithNonHarvestableConnections();
  }

  void runDefaultAllConnectionsHarvestable() throws Exception {
    show("\n*** Run with default: all connections are harvestable ***");

    try {
      int INITIAL_POOL_SIZE = 10;
      final String POOL_NAME = "UCPHarvesting_pool1";
      Connection conns[] = new Connection[INITIAL_POOL_SIZE];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);
      /*
       * ConnectionHarvestTriggerCount specifies the available connections
       * threshold that triggers connection harvesting. For example, if the
       * connection harvest trigger count is set to 5, connection harvesting
       * is triggered when the number of available connections in the pool
       * drops to 5.
       *
       * A value of Integer.MAX_VALUE disables connection harvesting.
       * By default, connection harvesting is disabled.
       */
      pds.setConnectionHarvestTriggerCount(5);
      /*
       * ConnectionHarvestMaxumCount specifies the maximum number of
       * borrowed connections that can be returned to the pool, once
       * connection harvesting is triggered. The default is 1.
       */
      pds.setConnectionHarvestMaxCount(2);

      show("Connection pool " + POOL_NAME + " configured");
      show("Initial pool size: " + pds.getInitialPoolSize());

      show("\nBorrowing 4 connections, conns[0] and conns[1] are LRU");

      TestHarvestingCallback[] cbks = new TestHarvestingCallback[5];
      for (int i = 0; i < 4; i++) {
        conns[i] = pds.getConnection();
        // Register harvesting callbacks to cleanup reclaimed connections.
        cbks[i] = new TestHarvestingCallback(conns[i]);
        ((HarvestableConnection) conns[i]).registerConnectionHarvestingCallback(cbks[i]);
        makeJDBCCalls(conns[i]);
      }

      showPoolStatistics("\nAfter borrowing 4 connections", pds);

      // Borrowing the 5th connection to trigger harvesting
      show("\nBorrowing 5th connection to trigger harvesting ...");
      conns[4] = pds.getConnection();
      cbks[4] = new TestHarvestingCallback(conns[4]);
      ((HarvestableConnection) conns[4]).registerConnectionHarvestingCallback(cbks[4]);

      // Harvesting should happen
      Thread.sleep(15000);

      // After harvesting, there will be 7 available connections and
      // 3 borrowed connections in the pool.
      showPoolStatistics("\nAfter harvesting", pds);

      // conns[0] and [1]'s physical connections should be "harvested"
      // by the pool and these two logical connections should be closed
      show("\nChecking on the 5 borrowed connections ...");
      show("  conns[0] should be closed -- " + conns[0].isClosed());
      show("  conns[1] should be closed -- " + conns[1].isClosed());
      show("  conns[2] should be open -- "   + !conns[2].isClosed());
      show("  conns[3] should be open -- "   + !conns[3].isClosed());
      show("  conns[4] should be open -- "   + !conns[4].isClosed());

      // Returning all connections to pool.
      for (int i = 2; i < 5; i++)
        conns[i].close();

      destroyConnectionPool(POOL_NAME);
    } catch (Throwable e) {
      showError("runDefaultAllConnectionsHarvestable", e);
    }

    show("\n*** Run with default completes ***");
  }

  void runWithNonHarvestableConnections() throws Exception {
    show("\n*** Run with non-harvestable connections ***");

    try {
      int INITIAL_POOL_SIZE = 10;
      final String POOL_NAME = "UCPHarvesting_pool2";
      Connection conns[] = new Connection[INITIAL_POOL_SIZE];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);
      /*
       * ConnectionHarvestTriggerCount specifies the available connections
       * threshold that triggers connection harvesting. For example, if the
       * connection harvest trigger count is set to 5, connection harvesting
       * is triggered when the number of available connections in the pool
       * drops to 5.
       *
       * A value of Integer.MAX_VALUE disables connection harvesting.
       * By default, connection harvesting is disabled.
       */
      pds.setConnectionHarvestTriggerCount(5);
      /*
       * ConnectionHarvestMaxumCount specifies the maximum number of
       * borrowed connections that can be returned to the pool, once
       * connection harvesting is triggered. The default is 1.
       */
      pds.setConnectionHarvestMaxCount(2);

      show("Connection pool " + POOL_NAME + " configured");
      show("Initial pool size: " + pds.getInitialPoolSize());

      show("\nBorrowing 4 connections, conns[0] and conns[1] are LRU");

      TestHarvestingCallback[] cbks = new TestHarvestingCallback[5];
      for (int i = 0; i < 4; i++) {
        conns[i] = pds.getConnection();
        // Register harvesting callbacks to cleanup reclaimed connections.
        cbks[i] = new TestHarvestingCallback(conns[i]);
        ((HarvestableConnection) conns[i]).registerConnectionHarvestingCallback(cbks[i]);
        makeJDBCCalls(conns[i]);
      }

      show("\nMarking conns[0] and conns[1] as non-harvestable");
      // Assuming application is doing critical work on conns[0] and [1]
      // and doesn't want those 2 connections to be "harvested".
      // Mark conns[0] and [1] as non-harvestable connections.
      ((HarvestableConnection) conns[0]).setConnectionHarvestable(false);
      ((HarvestableConnection) conns[1]).setConnectionHarvestable(false);

      showPoolStatistics("\nAfter borrowing 4 connections", pds);

      // Borrowing the 5th connection to trigger harvesting
      show("\nBorrowing 5th connection to trigger harvesting ...");
      conns[4] = pds.getConnection();
      cbks[4] = new TestHarvestingCallback(conns[4]);
      ((HarvestableConnection) conns[4]).registerConnectionHarvestingCallback(cbks[4]);

      // Harvesting should happen
      Thread.sleep(15000);

      // After harvesting, there will be 7 available connections and
      // 3 borrowed connections in the pool.
      showPoolStatistics("\nAfter harvesting", pds);

      // conns[2] and [3]'s physical connections should be "harvested"
      // by the pool and these two logical connections should be closed.
      // conns[0] and [1]'s physical connections will not be "harvested".
      show("\nChecking on the 5 borrowed connections ...");
      show("  conns[0] should be open -- "   + !conns[0].isClosed());
      show("  conns[1] should be open -- "   + !conns[1].isClosed());
      show("  conns[2] should be closed -- " + conns[2].isClosed());
      show("  conns[3] should be closed -- " + conns[3].isClosed());
      show("  conns[4] should be open -- "   + !conns[4].isClosed());

      // Returning all connections to pool.
      conns[0].close();
      conns[1].close();
      conns[4].close();

      destroyConnectionPool(POOL_NAME);
    } catch (Throwable e) {
      showError("runWithNonHarvestableConnections", e);
    }

    show("\n*** Run with non-harvestable connections completes ***");
  }

  // See sample UCPBasic.java for basic steps to set up a connection pool.
  PoolDataSource createPoolDataSource(String poolName) throws Exception {
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS);
    pds.setURL(url);
    pds.setUser(user);
    pds.setPassword(password);
    pds.setConnectionPoolName(poolName);
    pds.setInitialPoolSize(10);
    pds.setMaxPoolSize(10);
    pds.setTimeoutCheckInterval(5);

    return pds;
  }

  void destroyConnectionPool(String poolName) {
    try {
      UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager()
        .destroyConnectionPool(poolName);
      show("\nConnection pool " + poolName + " destroyed");
    } catch (Throwable e) {
      showError("destroyConnectinoPool", e);
    }
  }

  void showPoolStatistics(String prompt, PoolDataSource pds)
    throws SQLException {
    show(prompt + " -");
    show("  Available connections: " + pds.getAvailableConnectionsCount());
    show("  Borrowed connections: " + pds.getBorrowedConnectionsCount());
  }

  // Simple query
  void makeJDBCCalls(Connection conn) {
    try (Statement statement = conn.createStatement()) {
      statement.execute("SELECT 1 FROM DUAL");
    } catch (SQLException exc) {
      showError("makeJDBCCalls", exc);
    }
  }

  static void show(String msg) {
    System.out.println(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.out.println(msg + " hit error: " + exc.getMessage());
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

  /*
   * Sample connection harvesting callback implementation.
   */
  class TestHarvestingCallback implements ConnectionHarvestingCallback {
    private Object objForCleanup = null;

    public TestHarvestingCallback(Object objForCleanup) {
      this.objForCleanup = objForCleanup;
    }

    public boolean cleanup() {
      try {
        doCleanup(objForCleanup);
      } catch (Exception exc) {
        return false;
      }

      return true;
    }

    private void doCleanup(Object obj) throws Exception {
      ((Connection) obj).close();
    }
  }
}

