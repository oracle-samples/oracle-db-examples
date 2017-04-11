/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/

/*
   DESCRIPTION
   Connection Labeling is used when an application wants to request a 
   particular connection with the desired label from the connection pool. 
   
   Connection Labeling enables an application to associate custom labels 
   to a connection. By associating labels with a connection, an application
   can search and retrieve an already initialized connection from the pool 
   and avoid the time and cost of connection re-initialization. Connection 
   labeling also makes it faster to find/retrieve connections 
   with specific properties (specified through labels).
   
   Connection labeling is application-driven and requires two interfaces.  
   (a) oracle.ucp.jdbc.LabelableConnection: It is used to retrieve, apply 
   and remove connection labels. 
   (b) oracle.ucp.ConnectionLabelingCallback: used to create a labeling 
   callback that determines if a connection with a requested label 
   already exists. Refer to ConnectionLabelingCallback in UCP Javadoc 
  (http://docs.oracle.com/database/121/JJUAR/toc.htm) 
   
  Step 1: Enter the database details in this file. 
          DB_USER, DB_PASSWORD, DB_URL and CONN_FACTORY_CLASS_NAME are required                      
   Step 2: Run the sample with "ant UCPConnectionLabelingSample"
 
   NOTES
     Use JDK 1.7 and above

   MODIFIED    (MM/DD/YY)
    nbsundar    12/15/15 - .
    nbsundar    11/24/15 - update
    nbsundar    03/09/15 - Creation (tzhou - Contributor)
 */
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Map;
import java.util.Set;
import java.util.Properties;

import oracle.ucp.ConnectionLabelingCallback;
import oracle.ucp.jdbc.LabelableConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class UCPConnectionLabelingSample {
  final static String DB_URL= "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(HOST=myhost)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=myorcldbservicename)))"; 
  final static String DB_USER = "hr";
  final static String DB_PASSWORD = "hr";
  final static String CONN_FACTORY_CLASS_NAME = "oracle.jdbc.pool.OracleDataSource";
   
  /*  The sample demonstrates UCP's Connection Labeling feature. 
   *(1) Set up the connection pool:  
   * Initialize the pool with 2 connections (InitialPoolSize = 2) and 
   * register a labeling callback (TestConnectionLabelingCallback).    
   *(2) Run the sample for connection Labeling: 
   *  (2.1) Get the 1st connection from UCP and label the connection
   *  (2.2) Request 2nd connection with the same label  
   *  (2.3) Notice that the cost() method in TestConnectionLabelingCallback
   *   gets invoked on connections in the pool.  The cost() method projects 
   *   the cost of configuring connections considering label-matching 
   *   differences. The pool uses this method to select a connection 
   *   with the least reconfiguration cost. 
   *  (2.4) If the pool finds a connection with cost 0, it returns the 
   *   connection without calling configure(); for any connection with 
   *   above-zero cost, the pool invokes configure() in the labeling
   *   callback, and then returns the connection to application.
   *  (2.5) The purpose of the configure() method is to bring the 
   *   connection to the desired state, which could include both 
   *   client-side and server-side actions. The method should also 
   *   apply or remove labels from the connection.
   */
  public static void main(String args[]) throws Exception {
    UCPConnectionLabelingSample sample = new UCPConnectionLabelingSample();    
    // Demonstrates Connection Labeling
    sample.run();
  }
 /*
  * Shows UCP's Connection labeling feature.
  */
  void run() throws Exception {
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();

    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS_NAME);
    pds.setUser(DB_USER);
    pds.setPassword(DB_PASSWORD);
    pds.setURL(DB_URL);
    // Set UCP properties
    pds.setConnectionPoolName("LabelingSamplePool");
    pds.setInitialPoolSize(2);

    // Register connection labeling callback
    TestConnectionLabelingCallback cbk = new TestConnectionLabelingCallback();
    // Registers a connection labeling callback with the connection pool
    pds.registerConnectionLabelingCallback(cbk);

    System.out.println("Initial available connection number: "
        + pds.getAvailableConnectionsCount());

    // Fresh connection from pool
    System.out.println("Requesting a regular connection from pool ...");
    Connection conn1 = pds.getConnection();
    System.out.println("Available connection number: "
        + pds.getAvailableConnectionsCount());
     
    // Change the transaction isolation level of the conn1 to 
    // java.sql.Connection.TRANSACTION_SERIALIZABLE
    conn1.setTransactionIsolation(Connection.TRANSACTION_SERIALIZABLE);
    doSQLWork(conn1, 5);

    // Now apply a connection label to this connection
    ((LabelableConnection) conn1).applyConnectionLabel("TRANSACTION_ISOLATION",
        "8");

    // Done with this connection for now, return it to pool
    System.out.println("Returning labeled connection to pool ...");
    conn1.close();
    System.out.println("Available connection number: "
        + pds.getAvailableConnectionsCount());

    Thread.sleep(10000);

    // The application wants to use connection again

    // Preferred connection label
    Properties label = new Properties();  
    label.setProperty("TRANSACTION_ISOLATION", "8");

    // Request connection with the preferred label
    System.out.println("Requesting connection with preferred label ...");
    Connection conn2 = pds.getConnection(label);
    System.out.println("Available connection number: "
        + pds.getAvailableConnectionsCount());

    System.out.println("Again returning labelled connection to pool ...");
    conn2.close();
    System.out.println("Available connection number: "
        + pds.getAvailableConnectionsCount());
  }
  
 /*
  *  The method shows database operations. 
  *  It creates a EMP_LIST table and will do an insert, update and select 
  *  on the new table created.
  */
  public static void doSQLWork(Connection conn, int loopstoRun) {
    for (int i = 0; i < loopstoRun; i++) {
      try {
        conn.setAutoCommit(false);
        // Prepare a statement to execute the SQL Queries.
        Statement statement = conn.createStatement();      

        // Create table EMP_LIST        
        statement.executeUpdate("create table EMP_LIST(EMPLOYEEID NUMBER,"
            + "EMPLOYEENAME VARCHAR2 (20))");
       // Insert few records into table EMP_LIST
        statement.executeUpdate("insert into EMP_LIST values(1, 'Jennifer Jones')");
        statement.executeUpdate("insert into EMP_LIST values(2, 'Alex Debouir')");

        // Update a record on EMP_LIST table.
        statement.executeUpdate("\n update EMP_LIST set EMPLOYEENAME='Alex Deborie'"
            + " where EMPLOYEEID=2");

        // Verify the contents of table EMP_LIST
        ResultSet resultSet = statement.executeQuery("select * from EMP_LIST");
        while (resultSet.next()) {
         // System.out.println(resultSet.getInt(1) + " " + resultSet.getString(2));
        }        
        // Close ResultSet and Statement
        resultSet.close();
        statement.close();
        
        resultSet = null;
        statement = null;
      }
      catch (SQLException e) {
        System.out.println("UCPConnectionLabelingSample - "
            + "doSQLWork()-SQLException occurred : " + e.getMessage());
      }
      finally {
        // Clean-up after everything
        try (Statement statement = conn.createStatement()) {
          statement.execute("drop table EMP_LIST");
        }
        catch (SQLException e) {
          System.out.println("UCPConnectionLabelingSample - "
              + "doSQLWork()- SQLException occurred : " + e.getMessage());
        }
      }
    }
  } 
} 

/*
 *  Sample labeling callback implementation.
 */
class TestConnectionLabelingCallback implements ConnectionLabelingCallback {
  public TestConnectionLabelingCallback() {
  }  
 /*
  *   Projects the cost of configuring connections considering 
  *   label-matching differences.  
  */
  public int cost(Properties reqLabels, Properties currentLabels) {
    // Case 1: exact match
    if (reqLabels.equals(currentLabels)) {
      System.out.println("## Exact match found!! ##");
      return 0;
    }

    // Case 2: Partial match where some labels match with current labels
    String iso1 = (String) reqLabels.get("TRANSACTION_ISOLATION");
    String iso2 = (String) currentLabels.get("TRANSACTION_ISOLATION");
    boolean match = (iso1 != null && iso2 != null && iso1
        .equalsIgnoreCase(iso2));
    Set rKeys = reqLabels.keySet();
    Set cKeys = currentLabels.keySet();
    if (match && rKeys.containsAll(cKeys)) {
      System.out.println("## Partial match found!! ##");
      return 10;
    }
    // Case 3: No match 
    // Do not choose this connection.
    System.out.println("## No match found!! ##");
    return Integer.MAX_VALUE;
  }

 /*
  *  Configures the selected connection for a borrowing request before 
  *  returning the connection to the application.
  */
  public boolean configure(Properties reqLabels, Object conn) {
    try {
      String isoStr = (String) reqLabels.get("TRANSACTION_ISOLATION");
      ((Connection) conn).setTransactionIsolation(Integer.valueOf(isoStr));

      LabelableConnection lconn = (LabelableConnection) conn;

      // Find the unmatched labels on this connection
      Properties unmatchedLabels = lconn
          .getUnmatchedConnectionLabels(reqLabels);

      // Apply each label <key,value> in unmatchedLabels to connection
      for (Map.Entry<Object, Object> label : unmatchedLabels.entrySet()) {
        String key = (String) label.getKey();
        String value = (String) label.getValue();
        lconn.applyConnectionLabel(key, value);
      }
    }
    catch (Exception exc) {
      return false;
    }
    return true;
  }
} 


