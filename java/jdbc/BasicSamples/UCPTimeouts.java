/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates key connection timeout features of the
 * Oracle Universal Connection Pool (UCP). These include:
 *   1) ConnectionWaitTimeout
 *   2) InactiveConnectionTimeout
 *   3) TimeToLiveConnectionTimeout
 *   4) AbandonedConnectionTimeout
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
 *   java UCPTimeouts -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Timer;
import java.util.TimerTask;

import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import oracle.ucp.jdbc.PoolDataSource;


public class UCPTimeouts {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  public static void main(String args[]) throws Exception {
    UCPTimeouts sample = new UCPTimeouts();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  void run() throws Exception {
    demoConnectionWaitTimeout();
    demoInactiveConnectionTimeout();
    demoTimeToLiveConnectionTimeout();
    demoAbandonedConnectionTimeout();
  }

  /*
   * The connection wait timeout specifies how long, in seconds, application
   * requests wait to obtain a connection, if there are no available
   * connections inside the pool. The application receives an SQLException
   * if the timeout is reached.
   *
   * A value of 0 disables this feature. The default is 3 seconds.
   */
  private void demoConnectionWaitTimeout() {
    show("\n*** Demo ConnectionWaitTimeout ***");

    try {
      final int MAX_POOL_SIZE = 5;
      final String POOL_NAME = "UCPTimeouts_pool1";
      Connection conns[] = new Connection[MAX_POOL_SIZE];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);
      pds.setMaxPoolSize(MAX_POOL_SIZE);
      // Set ConnectionWaitTimeout to 8 seconds
      pds.setConnectionWaitTimeout(8);
      pds.setTimeoutCheckInterval(5);

      show("Connection pool " + POOL_NAME + " configured");
      show("Max pool size: " + pds.getMaxPoolSize());

      show("\nBorrow connections to reach max pool size.");

      for (int i = 0; i < MAX_POOL_SIZE; i++) {
        conns[i] = pds.getConnection();
      }

      showPoolStatistics("After all connections are borrowed", pds);

      try {
        show("\nNow trying to borrow another connection from pool ...");

        // This request is expected to fail after ConnectionWaitTimeout.
        Connection conn = pds.getConnection();
      } catch (Exception e) {
        show("\nGetting expected error after ConnectionWaitTimeout");
      }

      show("\nReturn all borrowed connections to pool");
      // Return all borrowed connections to pool.
      for (int i = 0; i < MAX_POOL_SIZE; i++) {
        conns[i].close();
        conns[i] = null;
      }

      destroyConnectionPool(POOL_NAME);

    } catch (Throwable e) {
      showError("demoConnectionWaitTimeout", e);
    }

    show("\n*** Demo ConnectionWaitTimeout completes ***");
  }

  /*
   * The inactive connection timeout specifies how long, in seconds,
   * an available connection can remain idle inside the pool, before
   * it is closed and removed from the pool. This timeout property is
   * only applicable to available connections and does not affect borrowed
   * connections.
   *
   * A value 0 disables this feature. By default, this timeout is disabled.
   */
  private void demoInactiveConnectionTimeout() {
    show("\n*** Demo InactiveConnectionTimeout ***");

    try {
      final int MIN_POOL_SIZE = 5;
      final int MAX_POOL_SIZE = 10;
      final String POOL_NAME = "UCPTimeouts_pool2";
      Connection conns[] = new Connection[MAX_POOL_SIZE];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);
      pds.setMinPoolSize(MIN_POOL_SIZE);
      pds.setMaxPoolSize(MAX_POOL_SIZE);
      // Set InactiveConnectionTimeout to 10 seconds
      pds.setInactiveConnectionTimeout(10);
      pds.setTimeoutCheckInterval(5);

      show("Connection pool " + POOL_NAME + " configured");
      show("Min pool size: " + pds.getMinPoolSize());
      show("Max pool size: " + pds.getMaxPoolSize());

      show("\nBorrow connections to reach min pool size.");

      // First borrow all connections in the pool
      for (int i = 0; i < MAX_POOL_SIZE; i++) {
        conns[i] = pds.getConnection();
      }

      // Return all connections beyond MinPoolSize to pool
      for (int i = MIN_POOL_SIZE; i < MAX_POOL_SIZE; i++) {
        conns[i].close();
      }

      showPoolStatistics("After borrowing connections", pds);

      show("\nSleep for 15 seconds to trigger InactiveConnectionTimeout.");
      show("Available connections beyond MinPoolSize are expected to close");

      try {
        Thread.sleep(15000);
      } catch (InterruptedException e) {}

      showPoolStatistics("\nAfter InactiveConnectionTimeout", pds);

      show("\nReturn all borrowed connections to pool");
      // Return all borrowed connections to pool.
      for (int i = 0; i < MIN_POOL_SIZE; i++) {
        conns[i].close();
        conns[i] = null;
      }

      destroyConnectionPool(POOL_NAME);

    } catch (Throwable e) {
      showError("demoInactiveConnectionTimeout", e);
    }

    show("\n*** Demo InactiveConnectionTimeout completes ***");
  }

  /*
   * The time-to-live connection timeout enables borrowed connections to
   * remain borrowed for a specific amount of time before the connection
   * is reclaimed by the pool. The timeout is in seconds.
   *
   * A value 0 disables this feature. By default, this timeout is disabled.
   */
  private void demoTimeToLiveConnectionTimeout() {
    show("\n*** Demo TimeToLiveConnectionTimeout ***");

    try {
      final int MAX_POOL_SIZE = 5;
      final String POOL_NAME = "UCPTimeouts_pool3";
      Connection conns[] = new Connection[MAX_POOL_SIZE];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);
      pds.setMaxPoolSize(MAX_POOL_SIZE);
      // Set TimeToLiveConnectionTimeout to 10 seconds
      pds.setTimeToLiveConnectionTimeout(10);
      pds.setTimeoutCheckInterval(5);

      show("Connection pool " + POOL_NAME + " configured");
      show("Max pool size: " + pds.getMaxPoolSize());

      show("\nBorrow connections to reach max pool size.");

      for (int i = 0; i < MAX_POOL_SIZE; i++) {
        conns[i] = pds.getConnection();
      }

      showPoolStatistics("After all connections are borrowed", pds);

      show("\nSleep for 15 seconds to trigger TimeToLiveConnectionTimeout.");
      show("All borrowed connections are expected to be returned to pool.");

      try {
        Thread.sleep(15000);
      } catch (InterruptedException e) {}

      showPoolStatistics("\nAfter TimeToLiveConnectionTimeout", pds);

      destroyConnectionPool(POOL_NAME);

    } catch (Throwable e) {
      showError("demoTimeToLiveConnectionTimeout", e);
    }

    show("\n*** Demo TimeToLiveConnectionTimeout completes ***");
  }

  /*
   * The abandoned connection timeout (ACT) enables a borrowed connection
   * to be reclaimed back into the connection pool, after that borrowed
   * connection has not been used for a specific amount of time.
   * The timeout is in seconds.
   *
   * A value 0 disables this feature. By default, this timeout is disabled.
   */
  private void demoAbandonedConnectionTimeout() {
    show("\n*** Demo AbandonedConnectionTimeout ***");

    try {
      final int MAX_POOL_SIZE = 10;
      final String POOL_NAME = "UCPTimeouts_pool4";
      Connection conns[] = new Connection[MAX_POOL_SIZE];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);
      pds.setMaxPoolSize(MAX_POOL_SIZE);
      // Set AbandonedConnectionTimeout to 10 seconds
      pds.setAbandonedConnectionTimeout(10);
      pds.setTimeoutCheckInterval(5);

      show("Connection pool " + POOL_NAME + " configured");
      show("Max pool size: " + pds.getMaxPoolSize());

      show("\nBorrow connections to reach max pool size.");

      for (int i = 0; i < MAX_POOL_SIZE; i++) {
        conns[i] = pds.getConnection();
      }

      showPoolStatistics("After all connections are borrowed", pds);

      Timer tm = new Timer(true);

      show("\nDo some work periodically only on 3 borrowed connections ...");

      for (int i = 0; i < 3; i++) {
        tm.schedule(new TestACTTimerTask(conns[i]), 1000, 1000);
      }

      show("\nSleep for 15 seconds to trigger AbandonedConnectionTimeout.");
      show("All borrowed connections other than the 3 are expected to be returned to pool.");

      try {
        Thread.sleep(15000);
      } catch (InterruptedException e) {}

      showPoolStatistics("\nAfter AbandonedConnectionTimeout", pds);

      // Cancel all timer tasks on the 3 borrowed connections
      tm.cancel();

      destroyConnectionPool(POOL_NAME);

    } catch (Throwable e) {
      showError("demoAbandonedConnectionTimeout", e);
    }

    show("\n*** Demo AbandonedConnectionTimeout completes ***");
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

  // Used for AbandonedConnectionTimeout only
  class TestACTTimerTask extends TimerTask {
    Connection conn = null;

    public TestACTTimerTask(Connection con) {
      conn = con;
    }

    public void run() {
      try (Statement statement = conn.createStatement()) {
        statement.execute("select 1 from dual");
      } catch (Exception ucpException) {}
    }
  }
}

