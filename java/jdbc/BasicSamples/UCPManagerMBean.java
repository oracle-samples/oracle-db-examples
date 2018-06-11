/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates how applications use UCP manager MBean's
 * administration functions. These include:
 *
 *   1)  createConnectionPool
 *   2)  stopConnectionPool
 *   3)  startConnectionPool
 *   4)  refreshConnectionPool
 *   5)  recycleConnectionPool
 *   6)  purgeConnectionPool
 *   7)  destoryConnectionPool
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
 *   java UCPManagerMBean -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;

import javax.management.MBeanServer;
import javax.management.MBeanServerFactory;
import javax.management.ObjectName;

import oracle.ucp.admin.UniversalConnectionPoolManagerMBean;
import oracle.ucp.admin.UniversalConnectionPoolManagerMBeanImpl;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;


public class UCPManagerMBean {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  final static String POOL_NAME = "UCPManagerMBean_pool";

  // Shared by all methods
  private PoolDataSource pds = null;

  private static MBeanServer mbs = null;

  // Shared by all methods
  private UniversalConnectionPoolManagerMBean mgrMBean = null;

  // Shared by all methods
  private String OBJECT_NAME = null;


  public static void main(String args[]) throws Exception {
    UCPManagerMBean sample = new UCPManagerMBean();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  void run() throws Exception {
    // Get the UniversalConnectionPoolManagerMBean instance.
    mgrMBean = UniversalConnectionPoolManagerMBeanImpl
      .getUniversalConnectionPoolManagerMBean();

    // Find an existing MBean Server
    mbs = (MBeanServer) MBeanServerFactory.findMBeanServer(null).iterator().next();
    pds = createPoolDataSource(POOL_NAME);

    OBJECT_NAME =
      "oracle.ucp.admin:name=UniversalConnectionPoolManagerMBean("+
      UniversalConnectionPoolManagerMBeanImpl.class.hashCode()+")";

    demoCreateConnectionPool();
    demoStartConnectionPool();
    demoStopConnectionPool();
    demoRefreshConnectionPool();
    demoRecycleConnectionPool();
    demoPurgeConnectionPool();
    demoDestroyConnectionPool();
  }

  private void demoCreateConnectionPool() {
    try {
      show("\n-- demoCreateConnectionPool -- ");

      // Build required parameters to invoke MBean operation.
      ObjectName objName = new ObjectName(OBJECT_NAME);
      Object[] params = { pds };
      String[] signature = {"oracle.ucp.UniversalConnectionPoolAdapter"};

      // Create the pool using Manager MBean.
      mbs.invoke(objName, "createConnectionPool", params, signature);

      show("\nConnection pool " + POOL_NAME + " is created from MBean");
    } catch (Exception e) {
      showError("demoCreateConnectionPool", e);
    }
  }

  private void demoStartConnectionPool() {
    try {
      show("\n-- demoStartConnectionPool -- ");

      // Build required parameters to invoke MBean operation.
      ObjectName objName = new ObjectName(OBJECT_NAME);
      Object[] params = { POOL_NAME };
      String[] signature = { "java.lang.String" };

      // Start the pool using Manager MBean.
      mbs.invoke(objName, "startConnectionPool", params, signature);

      show("\nConnection pool " + POOL_NAME + " is started from MBean");
      showPoolStatistics("After pool start", pds);
    } catch(Exception e) {
      showError("demoStartConnectionPool", e);
    }
  }

  private void demoStopConnectionPool() {
    try {
      show("\n-- demoStopConnectionPool -- ");

      // Build required parameters to invoke MBean operation.
      ObjectName objName = new ObjectName(OBJECT_NAME);
      Object[] params = { POOL_NAME };
      String[] signature = { "java.lang.String" };

      // Stop the pool using Manager MBean.
      mbs.invoke(objName, "stopConnectionPool", params, signature);

      show("\nConnection pool " + POOL_NAME + " is stopped from MBean");
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

      // Build required parameters to invoke MBean operation.
      ObjectName objName = new ObjectName(OBJECT_NAME);
      Object[] params = { POOL_NAME };
      String[] signature = { "java.lang.String" };

      // Refresh the connection pool using Manager MBean.
      mbs.invoke(objName, "refreshConnectionPool", params, signature);
      show("\nConnection pool " + POOL_NAME + " is refreshed from MBean");

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

      // Build required parameters to invoke MBean operation.
      ObjectName objName = new ObjectName(OBJECT_NAME);
      Object[] params = { POOL_NAME };
      String[] signature = { "java.lang.String" };

      // Recycle the pool using Manager MBean.
      mbs.invoke(objName, "recycleConnectionPool", params, signature);
      show("\nConnection pool " + POOL_NAME + " is recycled from MBean");

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

      // Build required parameters to invoke MBean operation.
      ObjectName objName = new ObjectName(OBJECT_NAME);
      Object[] params = { POOL_NAME };
      String[] signature = { "java.lang.String" };

      // Purge the pool using Manager MBean.
      mbs.invoke(objName, "purgeConnectionPool", params, signature);
      show("\nConnection pool " + POOL_NAME + " is purged from MBean");

      // All connections are removed, so 0 for both available and borrowed.
      showPoolStatistics("After pool purge", pds);
    } catch (Exception e) {
      showError("demoPurgeConnectionPool", e);
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

      // Build required parameters to invoke MBean operation.
      ObjectName objName = new ObjectName(OBJECT_NAME);
      Object[] params = { POOL_NAME };
      String[] signature = { "java.lang.String" };

      // Destroy the pool using Manager MBean.
      mbs.invoke(objName, "destroyConnectionPool", params, signature);
      show("\nConnection pool " + POOL_NAME + " is destroyed from MBean");

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

