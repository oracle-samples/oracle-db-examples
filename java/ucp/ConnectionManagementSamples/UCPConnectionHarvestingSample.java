/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/
/*
 DESCRIPTION
 The Connection Harvesting feature ensures that the pool does not run out of
 available connections by reclaiming borrowed connections on-demand.  It is 
 useful when an application holds a connection from a pool for a long time 
 without releasing it. By setting the appropriate HarvestTriggerCount and 
 HarvestMaxCount, user instructs UCP to reclaim some or all of these 
 borrowed connections to ensure there are enough in the pool. 
 
 Methods for connection harvesting include: 
 (1)setConnectionHarvestable(): on a per-connection basis, specifies whether 
 it is harvestable by the pool.  The default is harvestable.   
 (2)setConnectionHarvestMaxCount(): Maximum number of connections that may be
 harvested when harvesting occurs.
 (3)setConnectionHarvestTriggerCount(): Specifies the available connection
 threshold that triggers connection harvesting. 
 For example., if the harvest trigger count is set to 10, then harvesting is 
 triggered when the number of available connections in the pool drops to 10.   

 Step 1: Enter the database details in this file. 
         DB_USER, DB_PASSWORD, DB_URL and CONN_FACTORY_CLASS_NAME are required                   
 Step 2: Run the sample with "ant UCPConnectionHarvestingSample"

 NOTES
 Use JDK 1.7 and above

 MODIFIED    (MM/DD/YY)
 nbsundar    03/09/15 - Creation (Contributor - tzhou)
 */
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.ucp.ConnectionHarvestingCallback;
import oracle.ucp.jdbc.HarvestableConnection;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

public class UCPConnectionHarvestingSample {
  final static String DB_URL=  "jdbc:oracle:thin:@(DESCRIPTION=(ADDRESS=(HOST=myhost)(PORT=1521)(PROTOCOL=tcp))(CONNECT_DATA=(SERVICE_NAME=myorcldbservicename)))";  
  final static String DB_USER                 = "hr";
  final static String DB_PASSWORD             = "hr";
  final static String CONN_FACTORY_CLASS_NAME = "oracle.jdbc.pool.OracleDataSource";

  /*
   * The sample demonstrates UCP's Connection Harvesting feature. 
   *(1)Set the connection pool properties. 
   * PoolSize=10 connections, HarvestMaxCount=2 and HarvestTriggerCount=5 
   *(2)Run the sample with connection Harvesting.
   * (2.1) Get 4 connections from UCP and perform a database operation 
   * (2.2) Get a 5th connection which triggers harvesting 
   * (2.3) Notice that conns[0] and conns[1] are reclaimed as part of 
   *  harvesting based on LRU (Least Recently Used) algorithm. 
   * (2.4) Notice that number of available conns=7 and borrowed conns=3 
   *(3) Run the sample without connection harvesting. 
   * (3.1) Get 4 connections from UCP and perform a database operation 
   * (3.2) Mark conns[0] and conns[1] as non-harvestable 
   * (3.3) Get a 5th connection which triggers harvesting 
   * (3.4) Notice that conns[2] and conns[3] are reclaimed as part of
   *  harvesting and conns[0] and conns[1] are not harvested or released
   * (3.5) Notice that number of available connections=7 and borrowed conns= 3
   */
  public static void main(String args[]) throws Exception {
    UCPConnectionHarvestingSample sample = new UCPConnectionHarvestingSample();
    sample.run();
  }

  /*
   * Shows the outcomes with and without HarvestableConnection.
   */
  void run() throws Exception {
    PoolDataSource pds = PoolDataSourceFactory.getPoolDataSource();
    pds.setConnectionFactoryClassName(CONN_FACTORY_CLASS_NAME);
    pds.setUser(DB_USER);
    pds.setPassword(DB_PASSWORD);
    pds.setURL(DB_URL);
    // Set UCP properties
    pds.setConnectionPoolName("HarvestingSamplePool");
    pds.setInitialPoolSize(10);
    pds.setMaxPoolSize(25);

    // Configure connection harvesting:
    // Borrowed connections could be held for long thus causing connection pool
    // to run out of available connections. Connection Harvesting helps in
    // reclaiming borrowed connections thus ensuring at least some are
    // always available.
    pds.setConnectionHarvestTriggerCount(5);
    pds.setConnectionHarvestMaxCount(2);

    // demonstrates HavestableConnection behaviour
    runWithHarvestableConnection(pds);
    // demonstrates Non-HarvestableConnection behaviour
    runWithoutHarvestableConnection(pds);
  }

  /*
   * Displays how the harvestable connection works.
   */
  void runWithHarvestableConnection(PoolDataSource pds) throws Exception {
    System.out.println("## Run with Harvestable connections ##");
    System.out.println("Initial available connections: "
        + pds.getAvailableConnectionsCount());

    Connection[] conns = new Connection[5];
    TestConnectionHarvestingCallback[] cbks = new TestConnectionHarvestingCallback[10];

    // First borrow 4 connections--conns[0] and conns[1] are least-recently used
    for (int i = 0; i < 4; i++) {
      conns[i] = pds.getConnection();
      cbks[i] = new TestConnectionHarvestingCallback(conns[i]);
      // Registers a ConnectionHarvestingCallback with the this connection.
      ((HarvestableConnection) conns[i])
          .registerConnectionHarvestingCallback(cbks[i]);
      // Perform a database operation
      doSQLWork(conns[i], 2);
    }

    // Get another new connection to trigger harvesting
    conns[4] = pds.getConnection();
    cbks[4] = new TestConnectionHarvestingCallback(conns[4]);
    ((HarvestableConnection) conns[4])
        .registerConnectionHarvestingCallback(cbks[4]);

    System.out.println("Requested 5 connections ...");

    System.out.println("Available connections: "
        + pds.getAvailableConnectionsCount());
    System.out.println("Borrowed connections: "
        + pds.getBorrowedConnectionsCount());
    System.out.println("Waiting for 30 secs to trigger harvesting");
    // Harvesting should happen
    Thread.sleep(30000);

    // conns[0] and conns[1]'s physical connections should be "harvested"
    // by the pool and these two logical connections should be closed
    System.out.println("Checking on the five connections ...");
    System.out.println("  conns[0] should be closed --" + conns[0].isClosed());
    System.out.println("  conns[1] should be closed --" + conns[1].isClosed());
    System.out.println("  conns[2] should be open --" + !conns[2].isClosed());
    System.out.println("  conns[3] should be open --" + !conns[3].isClosed());
    System.out.println("  conns[4] should be open --" + !conns[4].isClosed());

    System.out.println("Checking on the pool ...");
    System.out.println("  Available connections should be 7: "
        + (pds.getAvailableConnectionsCount() == 7));
    System.out.println("  Borrowed connections should be 3: "
        + (pds.getBorrowedConnectionsCount() == 3));

    for (int i = 2; i < 5; i++)
      conns[i].close();
  }

  /*
   * The method displays first_name and last_name from employees table
   */
  void runWithoutHarvestableConnection(PoolDataSource pds) throws Exception {
    System.out.println("## Run without harvestable connections ##");
    System.out.println("Initial available connections: "
        + pds.getAvailableConnectionsCount());

    Connection[] conns = new Connection[5];
    TestConnectionHarvestingCallback[] cbks = new TestConnectionHarvestingCallback[10];

    // First borrow 4 connections -- conns[0] and conns[1] are least-recently
    // used
    for (int i = 0; i < 4; i++) {
      conns[i] = pds.getConnection();
      cbks[i] = new TestConnectionHarvestingCallback(conns[i]);
      // Registers a ConnectionHarvestingCallback with the this connection.
      ((HarvestableConnection) conns[i])
          .registerConnectionHarvestingCallback(cbks[i]);
      // Perform a database operation
      doSQLWork(conns[i], 2);
    }

    // Assuming the application is doing critical work on conns[0] and conns[1]
    // and doesn't want these 2 to be "harvested" automatically.
    // Mark conns[0] and conns[1] as non-harvestable connections.
    ((HarvestableConnection) conns[0]).setConnectionHarvestable(false);
    ((HarvestableConnection) conns[1]).setConnectionHarvestable(false);

    // Get another connection to trigger harvesting
    conns[4] = pds.getConnection();
    cbks[4] = new TestConnectionHarvestingCallback(conns[4]);
    ((HarvestableConnection) conns[4])
        .registerConnectionHarvestingCallback(cbks[4]);

    System.out.println("Requested 5 connections ...");

    System.out.println("Available connections: "
        + pds.getAvailableConnectionsCount());
    System.out.println("Borrowed connections: "
        + pds.getBorrowedConnectionsCount());

    System.out.println("Waiting for 30 secs to trigger harvesting");
    // Harvesting should happen
    Thread.sleep(30000);

    // conns[2] and conns[3]'s physical connections should be "harvested"
    // by the pool and these two logical connections should be closed.
    // conns[0] and conns[1]'s physical connections will not be "harvested".
    System.out.println("Checking on the five connections ...");
    System.out.println("  conns[0] should be open --" + !conns[0].isClosed());
    System.out.println("  conns[1] should be open --" + !conns[1].isClosed());
    System.out.println("  conns[2] should be closed --" + conns[2].isClosed());
    System.out.println("  conns[3] should be closed --" + conns[3].isClosed());
    System.out.println("  conns[4] should be open --" + !conns[4].isClosed());

    System.out.println("Checking on the pool ...");
    System.out.println("  Available connections should be 7: "
        + (pds.getAvailableConnectionsCount() == 7));
    System.out.println("  Borrowed connections should be 3: "
        + (pds.getBorrowedConnectionsCount() == 3));

    conns[0].close();
    conns[1].close();
    conns[4].close();
  }

  /*
   * Creates a EMP_TEST table and perform an insert, update and select database
   * operations on the new table created.
   */
  public static void doSQLWork(Connection conn, int loopstoRun) {
    for (int i = 0; i < loopstoRun; i++) {
      try {
        conn.setAutoCommit(false);
        // Prepare a statement to execute the SQL Queries.
        Statement statement = conn.createStatement();

        // Create table EMP_TEST
        statement.executeUpdate("create table EMP_TEST(EMPLOYEEID NUMBER,"
            + "EMPLOYEENAME VARCHAR2 (20))");
        // Insert some records into table EMP_TEST
        statement
            .executeUpdate("insert into EMP_TEST values(1, 'Jennifer Jones')");
        statement
            .executeUpdate("insert into EMP_TEST values(2, 'Alex Debouir')");

        // update a record on EMP_TEST table.
        statement
            .executeUpdate("update EMP_TEST set EMPLOYEENAME='Alex Deborie'"
                + " where EMPLOYEEID=2");
        // verify table EMP_TEST
        ResultSet resultSet = statement.executeQuery("select * from EMP_TEST");
        while (resultSet.next()) {
          // System.out.println(resultSet.getInt(1) + " "
          // + resultSet.getString(2));
        }
        // Close ResultSet and Statement
        resultSet.close();
        statement.close();

        resultSet = null;
        statement = null;
      }
      catch (SQLException e) {
        System.out.println("UCPConnectionHarvestingSample - "
            + "doSQLWork()-SQLException occurred : " + e.getMessage());
      }
      finally {
        // Clean-up after everything
        try (Statement statement = conn.createStatement()) {
          statement.execute("drop table EMP_TEST");
        }
        catch (SQLException e) {
          System.out.println("UCPConnectionHarvestingSample - "
              + "doSQLWork()- SQLException occurred : " + e.getMessage());
        }
      }
    }
  }

  /*
   * Sample connection harvesting callback implementation is shown here. Refer
   * to ConnectionHarvestingCallback in UCP Javadoc for more details.
   * (http://docs.oracle.com/database/121/JJUAR/toc.htm)
   */
  class TestConnectionHarvestingCallback implements
      ConnectionHarvestingCallback {
    private Object objForCleanup = null;

    public TestConnectionHarvestingCallback(Object objForCleanup) {
      this.objForCleanup = objForCleanup;
    }

    public boolean cleanup() {
      try {
        doCleanup(objForCleanup);
      }
      catch (Exception exc) {
        return false;
      }

      return true;
    }

    private void doCleanup(Object obj) throws Exception {
      ((Connection) obj).close();
    }
  }
}
