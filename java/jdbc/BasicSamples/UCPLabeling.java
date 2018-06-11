/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
 * DESCRIPTION
 * 
 * This code sample illustrates how applications use the connection labeling
 * feature of Oracle Universal Connection Pool (UCP).
 *
 * Connection Labeling allows applications to request pre-configured
 * connections identified by labels, in order to minimize connection
 * reinitialization cost.
 *
 * Connection Labeling does not impose any meaning on user-defined keys
 * or values; the meaning of user-defined keys and values is defined
 * solely by the application.
 *
 * Connection labeling is application-driven and requires the use of
 * two interfaces:
 *
 * (1) The oracle.ucp.jdbc.LabelableConnection interface is used to
 *     apply and remove connection labels, as well as retrieving labels
 *     that have been set on a connection.
 *
 * (2) The oracle.ucp.ConnectionLabelingCallback interface is used to
 *     create a labeling callback that determines whether or not
 *     a connection with a requested label already exists. If no connections
 *     exist, the interface allows current connections to be configured
 *     as required.
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
 *   java UCPLabeling -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;
import java.util.Properties;
import java.util.Set;

import oracle.ucp.ConnectionLabelingCallback;
import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.LabelableConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;


public class UCPLabeling {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  public static void main(String args[]) throws Exception {
    UCPLabeling sample = new UCPLabeling();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  void run() throws Exception {
    show("\n*** Demo Connection Labeling ***");

    try {
      final String POOL_NAME = "UCPLabeling_pool1";

      PoolDataSource pds = createPoolDataSource(POOL_NAME);
      pds.setInitialPoolSize(2);
      show("\nConnection pool " + POOL_NAME + " configured");
      show("Initial pool size: " + pds.getInitialPoolSize());

      // Register connection labeling callback
      ExampleLabelingCallback cbk = new ExampleLabelingCallback();
      pds.registerConnectionLabelingCallback(cbk);
      show("\nLabeling callback registered on the pool");

      // All initial connections in the pool do not have labels
      show("\nBorrowing a regular connection 1 (without labels) from pool ...");
      Connection conn1 = pds.getConnection();
      showPoolStatistics("After borrowing regular connection 1", pds);

      // Change session state and apply corresponding connection label,
      // using the LabelableConnection interface method.
      conn1.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
      ((LabelableConnection) conn1).applyConnectionLabel("TRANSACTION_ISOLATION", "8");
      show("\nApplied new label on connection 1");

      show("\nReturning labeled connection 1 to pool ...");
      conn1.close();
      showPoolStatistics("After returning labeled connection 1", pds);

      // Preferred connection label
      Properties label = new Properties();
      label.setProperty("TRANSACTION_ISOLATION", "8");

      // Specify preferred label(s) with the getConnection call
      show("\nBorrowing connection 2 with preferred label ...");
      Connection conn2 = pds.getConnection(label);
      showPoolStatistics("After borrowing labeled connection 2", pds);

      show("\nReturning labeled connection 2 to pool ...");
      conn2.close();
      showPoolStatistics("After returning labeled connection 2", pds);

      // Different preferred connection label
      Properties label2 = new Properties();
      // Connection.TRANSACTION_READ_COMMITTED == 2
      label2.setProperty("TRANSACTION_ISOLATION", "2");

      // Specify preferred label(s) with the getConnection call
      show("\nBorrowing connection 3 with different preferred label ...");
      Connection conn3 = pds.getConnection(label2);
      showPoolStatistics("After borrowing labeled connection 3", pds);

      show("\nReturning labeled connection 3 to pool ...");
      conn3.close();
      showPoolStatistics("After returning labeled connection 3", pds);

      destroyConnectionPool(POOL_NAME);

    } catch (Throwable e) {
      showError("UCPLabeling", e);
    }

    show("\n*** Demo Connection Labeling completes ***");
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

  class ExampleLabelingCallback implements ConnectionLabelingCallback {
    private boolean printed1 = false;
    private boolean printed2 = false;
    private boolean printed3 = false;

    public ExampleLabelingCallback() {}

    // The pool uses this method to select a connection with the least
    // reconfiguration cost. 0 means a perfect match; any positive integer
    // value indicates mismatch. It is up to the callback implementor
    // to decide how to assign the cost values.
    public int cost(Properties reqLabels, Properties currentLabels) {
      // Case 1: exact match
      if (reqLabels.equals(currentLabels)) {
        if (!printed1) {
          printed1 = true;
          show("  FROM callback cost(): ## Exact match found ##");
        }
        return 0;
      }

      // Case 2: partial match
      String iso1 = (String) reqLabels.get("TRANSACTION_ISOLATION");
      String iso2 = (String) currentLabels.get("TRANSACTION_ISOLATION");
      boolean match =
        (iso1 != null && iso2 != null && iso1.equalsIgnoreCase(iso2));
      Set rKeys = reqLabels.keySet();
      Set cKeys = currentLabels.keySet();
      if (match && rKeys.containsAll(cKeys)) {
        if (!printed2) {
          printed2 = true;
          show("  FROM callback cost(): ## Partial match found ##");
        }
        return 10;
      }

      // Case 3: no label matches application's preference.
      // Picking this connection incurs the highest reinitialization cost.
      if (!printed3) {
        printed3 = true;
        show("  FROM callback cost(): ## No match found ##");
      }
      return Integer.MAX_VALUE;
    }

    // In case a connection does not fully match the requested labels
    // (and corresponding session state), configures the connection
    // to establish the desired labels and state. This is done before
    // the connection is returned to applications for a borrow request.
    public boolean configure(Properties reqLabels, Object conn) {
      try {
        show("  Callback configure() is called to reinitialize connection");

        String isoStr = (String) reqLabels.get("TRANSACTION_ISOLATION");
        // Map label value to isolation level constants on Connection.
        ((Connection)conn).setTransactionIsolation(Integer.valueOf(isoStr));

        LabelableConnection lconn = (LabelableConnection) conn;

        // Find the unmatched labels on this connection
        Properties unmatchedLabels =
          lconn.getUnmatchedConnectionLabels(reqLabels);

        // Apply each label <key,value> in unmatchedLabels to connection.
        // A real callback should also apply the corresponding state change.
        for (Map.Entry<Object, Object> label : unmatchedLabels.entrySet()) {
          String key = (String) label.getKey();
          String value = (String) label.getValue();

          lconn.applyConnectionLabel(key, value);
        }
      } catch (Exception exc) {
        return false;
      }

      return true;
    }
  }
}

