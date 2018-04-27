/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates how applications use UCP manager's
 * administration functions. These include:
 *
 *   1)  createConnectionPool
 *   2)  stopConnectionPool
 *   3)  startConnectionPool
 *   4)  refreshConnectionPool
 *   5)  recycleConnectionPool
 *   6)  purgeConnectionPool
 *   7)  getConnectionPool
 *   8)  getConnectionPoolNames
 *   9)  destoryConnectionPool
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
 *   java UCPManager -url <url> -user <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;

import oracle.ucp.UniversalConnectionPool;
import oracle.ucp.UniversalConnectionPoolException;
import oracle.ucp.admin.UniversalConnectionPoolManager;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSourceImpl;


public class UCPManager {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  // Shared by all methods
  private PoolDataSource pds = null;

  // Shared by all methods
  private static UniversalConnectionPoolManager mgr = null;

  final static String POOL_NAME = "UCPManager_pool";

  public static void main(String args[]) throws Exception {
    UCPManager sample = new UCPManager();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  void run() throws Exception {
    mgr = UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager();
    pds = createPoolDataSource(POOL_NAME);

    demoCreateConnectionPool();
    demoStartConnectionPool();
    demoStopConnectionPool();
    demoRefreshConnectionPool();
    demoRecycleConnectionPool();
    demoPurgeConnectionPool();
    demoGetConnectionPool();
    demoGetConnectionPoolNames();
    demoDestroyConnectionPool();
  }

  private void demoCreateConnectionPool() {
    try {
      show("\n-- demoCreateConnectionPool -- ");

      // Creates the embedded connection pool instance in the data source.
      mgr.createConnectionPool((PoolDataSourceImpl) pds);

      show("\nConnection pool " + POOL_NAME + " is created from manager");
    } catch (Exception e) {
      showError("demoCreateConnectionPool", e);
    }
  }

  private void demoStartConnectionPool() {
    try {
      show("\n-- demoStartConnectionPool -- ");

      // Starts the embedded connection pool instance.
      mgr.startConnectionPool(POOL_NAME);

      show("\nConnection pool " + POOL_NAME + " is started from manager");
      showPoolStatistics("After pool start", pds);
    } catch(Exception e) {
      showError("demoStartConnectionPool", e);
    }
  }

  private void demoStopConnectionPool() {
    try {
      show("\n-- demoStopConnectionPool -- ");

      // Stops the embedded connection pool instance.
      mgr.stopConnectionPool(POOL_NAME);

      show("\nConnection pool " + POOL_NAME + " is stopped from manager");
      showPoolStatistics("After pool stop", pds);
    } catch (Exception e) {
      showError("demoStopConnectionPool", e);
    }
  }

  // Refreshing a connection pool replaces every connection in the pool
  // with a new connection. Any borrowed connection is marked for removal
  // only, and will be refreshed after the connection is returned to the pool.
  private void demoRefreshConnectionPool() {
    try {
      show("\n-- demoRefreshConnectionPool -- ");

      show("\nSets the initial pool size to 10");
      pds.setInitialPoolSize(10);

      show("\nBorrow a connection from the pool");
      Connection con = pds.getConnection();
      // There will be 9 available connections and 1 borrowed connection.
      showPoolStatistics("After borrow and before pool refresh", pds);

      // Refreshes the embedded connection pool instance.
      mgr.refreshConnectionPool(POOL_NAME);
      show("\nConnection pool " + POOL_NAME + " is refreshed from manager");

      // Only available connections are immediately refreshed, so there
      // will still be 9 available connections and 1 borrowed connection.
      showPoolStatistics("After pool refresh", pds);

      // This last connection will be refreshed after returned to pool.
      show("\nReturn the borrowed connection to the pool");
      con.close();
      // Wait for pool to asynchronously replace connection.
      Thread.sleep(20000);
      showPoolStatistics("After last return", pds);
    } catch (Exception e) {
      showError("demoRefreshConnectionPool", e);
    }
  }

  // Recycling a connection pool replaces only invalid connections in the pool
  // with new connections and does not replace borrowed connections.
  private void demoRecycleConnectionPool() {
    try {
      show("\n-- demoRecycleConnectionPool -- ");

      showPoolStatistics("Before any action", pds);

      show("\nBorrow a connection from the pool");
      Connection con = pds.getConnection();
      // There will be 9 available connections and 1 borrowed connection.
      showPoolStatistics("After borrow and before pool recycle", pds);

      // Recycles the embedded connection pool instance.
      mgr.recycleConnectionPool(POOL_NAME);
      show("\nConnection pool " + POOL_NAME + " is recycled from manager");

      // Only invalid connections are recycled, so there will still be
      // 9 available connections and 1 borrowed connection.
      showPoolStatistics("After pool recycle", pds);

      // Return last borrowed connection to the pool.
      con.close();
      // Wait for pool to asynchronously validate returned connection.
      Thread.sleep(20000);
    } catch (Exception e) {
      showError("demoRecycleConnectionPool", e);
    }
  }

  // Purging a connection pool removes every connection (available and
  // borrowed) from the connection pool and leaves the pool empty.
  private void demoPurgeConnectionPool() {
    try {
      show("\n-- demoPurgeConnectionPool -- ");

      showPoolStatistics("Before any action", pds);

      show("\nBorrow a connection from the pool");
      Connection con = pds.getConnection();
      // There will be 9 available connections and 1 borrowed connection.
      showPoolStatistics("After borrow and before pool purge", pds);

      // Purges the embedded connection pool instance.
      mgr.purgeConnectionPool(POOL_NAME);
      show("\nConnection pool " + POOL_NAME + " is purged from manager");

      // All connections are removed, so 0 for both available and borrowed.
      showPoolStatistics("After pool purge", pds);
    } catch (Exception e) {
      showError("demoPurgeConnectionPool", e);
    }
  }

  private void demoGetConnectionPool() {
    try {
      show("\n-- demoGetConnectionPool -- ");

      UniversalConnectionPool pool = mgr.getConnectionPool(POOL_NAME);

      show("\nObtained UCP pool object for " + POOL_NAME +
        ": " + pool);
    } catch (Exception e) {
      showError("demoGetConnectionPool", e);
    }
  }

  private void demoGetConnectionPoolNames() {
    try {
      show("\n-- demoGetConnectionPoolNames -- ");

      String names[] = mgr.getConnectionPoolNames();

      show("\nObtained all pool names in this UCP manager:");
      for (int i = 0; i < names.length; i++) {
        show("Pool [" +i +"] : " + names[i]);
      }
    } catch (Exception e) {
      showError("demoGetConnectionPoolNames", e);
    }
  }

  private void demoDestroyConnectionPool() {
    try {
      show("\n-- demoDestroyConnectionPool -- ");

      showPoolStatistics("Before any action", pds);

      show("\nBorrow a connection from the pool");
      Connection con = pds.getConnection();
      showPoolStatistics("After borrow", pds);

      show("\nReturn the connection to pool");
      con.close();
      showPoolStatistics("After return and before pool destroy", pds);

      // Destroys the embedded connection pool instance.
      mgr.destroyConnectionPool(POOL_NAME);
      show("\nConnection pool " + POOL_NAME + " is destroyed from manager");

      try {
        show("\nTry to borrow another connection from the pool ");
        pds.getConnection();
      } catch (Exception e) {
        show("\nGot expected error, cannot borrow since pool is destroyed");
      }
    } catch (Exception e) {
      showError("demoDestroyConnectionPool", e);
    }
  }

  // See sample UCPBasic.java for basic steps to set up a connection pool.
  PoolDataSource createPoolDataSource(String poolName) throws Exception {
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS);
    pds.setURL(url);
    pds.setUser(user);
    pds.setPassword(password);
    pds.setConnectionPoolName(poolName);

    return pds;
  }

  void showPoolStatistics(String prompt, PoolDataSource pds)
    throws SQLException {
    show(prompt + " -");
    show("  Available connections: " + pds.getAvailableConnectionsCount());
    show("  Borrowed connections: " + pds.getBorrowedConnectionsCount());
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
}

