/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates how applications use the MaxConnectionReuseTime
 * and MaxConnectionReuseCount features of Oracle Universal Connection Pool
 * (UCP).
 *
 * The maximum connection reuse time allows connections to be gracefully
 * closed and removed from the pool after a connection has been in use for
 * a specific amount of time. The timer for this property starts when a
 * connection is physically created. Borrowed connections are closed only
 * after they are returned to the pool and the reuse time is exceeded.
 *
 * This feature is typically used when a firewall exists between the pool tier
 * and the database tier and is setup to block connections based on time
 * restrictions. The blocked connections remain in the pool even though
 * they are unusable. In such scenarios, the connection reuse time can be
 * set to a smaller value than the firewall timeout policy.
 *
 * The time is measured in seconds. 0 disables the feature, which is
 * the default.
 *
 * The maximum connection reuse count works similarly, allowing a connection
 * to be closed and removed from the pool after it has been borrowed
 * a specific number of times.
 *
 * Value 0 disables the feature, which is the default.
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
 *   java UCPMaxConnReuse -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;

import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;


public class UCPMaxConnReuse {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  public static void main(String args[]) throws Exception {
    UCPMaxConnReuse sample = new UCPMaxConnReuse();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  void run() throws Exception {
    demoMaxConnectionReuseTime();
    demoMaxConnectionReuseCount();
  }

  public void demoMaxConnectionReuseTime() throws Exception {
    show("\n*** Demo MaxConnectionReuseTime ***");

    try {
      final String POOL_NAME = "UCPMaxConnReuse_pool1";
      Connection[] conns = new Connection[3];
      String[] connStrs = new String[3];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);

      // Each connection in the pool will be reusable for 25 seconds after
      // its creation. Then it will be gracefully closed and removed on
      // its next return to the pool.
      pds.setMaxConnectionReuseTime(25);

      show("Connection pool " + POOL_NAME + " configured");

      show("\nBorrow conns[0] from pool.");
      conns[0] = pds.getConnection();
      connStrs[0] = ((Object)conns[0]).toString();

      showPoolStatistics("After conns[0] is borrowed", pds);

      show("\nReturn conns[0] to pool.");
      conns[0].close();

      showPoolStatistics("After conns[0] is returned", pds);

      show("\nBorrow conns[1] from pool.");
      conns[1] = pds.getConnection();
      connStrs[1] = ((Object)conns[1]).toString();

      show("conns[0] and conns[1] should be equal : " +
           connStrs[0].equals(connStrs[1]));

      show("\nSleep for 30 seconds that exceeds MaxConnnectionReuseTime.");
      Thread.sleep(30000);

      show("\nconns[1] is not closed, since it's still borrowed.");
      showPoolStatistics("Just before conns[1] is returned to pool", pds);

      show("\nReturn conns[1] to pool.");
      show("This will close the physical connection in the pool.");
      // Close the second connection. Since this connection has exceeded
      // MaxConnectionReuseTime, it will be closed and removed from the pool.
      conns[1].close();

      showPoolStatistics("\nAfter conns[1] is returned", pds);

      // Get the third connection. This should be a new physical connection
      // from conns[1].
      show("\nBorrow conns[2] from pool.");
      conns[2] = pds.getConnection();
      connStrs[2] = ((Object)conns[2]).toString();

      show("conns[0] and conns[2] should not be equal : " +
           !connStrs[0].equals(connStrs[2]));

      show("conns[1] and conns[2] should not be equal : " +
           !connStrs[1].equals(connStrs[2]));

      show("\nReturn conns[2] to pool.");
      conns[2].close();

      destroyConnectionPool(POOL_NAME);

    } catch (Throwable e) {
      showError("demoMaxConnectionReuseTime", e);
    }

    show("\n*** Demo MaxConnectionReuseTime completes ***");
  }

  public void demoMaxConnectionReuseCount() throws Exception {
    show("\n*** Demo MaxConnectionReuseCount ***");

    try {
      final String POOL_NAME = "UCPMaxConnReuse_pool2";
      Connection[] conns = new Connection[3];
      String[] connStrs = new String[3];

      PoolDataSource pds = createPoolDataSource(POOL_NAME);

      // Each connection in the pool will be reusable for 2 borrow's
      // after its creation. Then it will be gracefully closed and
      // removed on its next (i.e., 2nd) return to the pool.
      pds.setMaxConnectionReuseCount(2);

      show("Connection pool " + POOL_NAME + " configured");

      show("\nBorrow conns[0] from pool.");
      conns[0] = pds.getConnection();
      connStrs[0] = ((Object)conns[0]).toString();

      showPoolStatistics("After conns[0] is borrowed", pds);

      show("\nReturn conns[0] to pool.");
      conns[0].close();

      showPoolStatistics("After conns[0] is returned", pds);

      show("\nBorrow conns[1] from pool.");
      conns[1] = pds.getConnection();
      connStrs[1] = ((Object)conns[1]).toString();

      show("conns[0] and conns[1] should be equal : " +
           connStrs[0].equals(connStrs[1]));

      show("\nconns[1]'s physical connection has reached MaxConnnectionReuseCount.");

      show("It is not closed right away, since it's still borrowed.");
      showPoolStatistics("\nJust before conns[1] is returned to pool", pds);

      show("\nReturn conns[1] to pool.");
      show("This will close the physical connection in the pool.");
      // Close the second connection. Since this connection has exceeded
      // MaxConnectionReuseCount, it will be closed and removed from the pool.
      conns[1].close();

      showPoolStatistics("\nAfter conns[1] is returned", pds);

      // Get the third connection. This should be a new physical connection
      // from conns[1].
      show("\nBorrow conns[2] from pool.");
      conns[2] = pds.getConnection();
      connStrs[2] = ((Object)conns[2]).toString();

      show("conns[0] and conns[2] should not be equal : " +
           !connStrs[0].equals(connStrs[2]));

      show("conns[1] and conns[2] should not be equal : " +
           !connStrs[1].equals(connStrs[2]));

      show("\nReturn conns[2] to pool.");
      conns[2].close();

      destroyConnectionPool(POOL_NAME);

    } catch (Throwable e) {
      showError("demoMaxConnectionReuseCount", e);
    }

    show("\n*** Demo MaxConnectionReuseCount completes ***");
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
}

