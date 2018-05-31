import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;

/**
 * This sample code demonstrates the functionality of Multi-tenant shared pools.
 * With the use of shared pools now it is possible for more than one tenant
 * datasources to share a common pool provided they are connecting to the same
 * database with a single url. To use shared pool functionality, all the tenant
 * datasources accessing shared pools should be defined in UCP XML configuration
 * file along with the pool properties. The code example shows how to get a
 * connection from a shared pool defined in xml.
 * 
 * The shared pool defined in sample XML config file has only one connection and
 * both the tenant datasources -tenat1_ds and tenant2_ds are reusing the same
 * connection to get the employee data from respective employee tables
 * (tenant1_emp and tenant2_emp) present in tenant1 PDB and tenant2 PDB.
 * 
 * 
 */
public class SharedPoolCodeSample {
  // UCP XML config file location URI
  private static final String xmlFileURI = "file:/test/ucp/config/SharedPoolCodeSample.xml";

  public static void main(String[] args) throws Exception {
    System.out.println("Multi-Tenant shared pool configuration using XML");

    // Java system property to specify the location of UCP XML configuration
    // file which has shared pool, datasource properties defined in it.
    System.setProperty("oracle.ucp.jdbc.xmlConfigFile", xmlFileURI);

    // The xml file used in this code example defines a connection pool with
    // connection-pool-name -"pool1" and two tenant datasources with
    // datasource-name as "tenant1_ds" and "tenant2_ds" which are using this
    // shared pool.

    // Get the datasource instance named as "tenant1_ds" in XML config file
    PoolDataSource tenant1_DS = PoolDataSourceFactory
        .getPoolDataSource("tenant1_ds");

    // Get a connection using tenant1 datasource
    Connection tenant1Conn = tenant1_DS.getConnection();

    // Run a query on the connection obtained using tenant1 datasource i.e.
    // tenant1_ds
    runQueryOnTenant1(tenant1Conn);

    // return tenant1 connection to the pool
    tenant1Conn.close();

    // Get the datasource instance named as "tenant2_ds" in XML config file
    PoolDataSource tenant2_DS = PoolDataSourceFactory
        .getPoolDataSource("tenant2_ds");

    // Get a connection using tenant2 datasource
    Connection tenant2Conn = tenant2_DS.getConnection();

    // Run a query on the connection obtained using tenant2 datasource i.e.
    // tenant2_ds
    runQueryOnTenant2(tenant2Conn);

    // return tenant2 connection to the pool
    tenant2Conn.close();

  }

  /**
   * Runs a query on the tenant1 table i.e. tenant1_emp to get the employee details
   * using the given connection.
   */
  private static void runQueryOnTenant1(Connection tenant1Conn) {
    try {
      String sql = "SELECT empno,ename FROM tenant1_emp";
      Statement st = tenant1Conn.createStatement();
      ResultSet rs = st.executeQuery(sql);
      System.out.println("Teant1 Employee Details :");
      while (rs.next()) {
        System.out.println("Employee ID = " + rs.getInt("empno")
            + "     Employee Name = " + rs.getString("ename"));
      }
      rs.close();
      st.close();

    } catch (SQLException e) {
      e.printStackTrace();
    }

  }

  /**
   * Runs a query on the tenant2 table i.e. tenant2_emp to get the employee details
   * using the given connection.
   */
  private static void runQueryOnTenant2(Connection tenant2Conn) {
    try {
      String sql = "SELECT empno,ename FROM tenant2_emp";
      Statement st = tenant2Conn.createStatement();
      ResultSet rs = st.executeQuery(sql);
      System.out.println("Teant2 Employee Details :");
      while (rs.next()) {
        System.out.println("Employee ID = " + rs.getInt("empno")
            + "     Employee Name = " + rs.getString("ename"));
      }
      rs.close();
      st.close();

    } catch (SQLException e) {
      e.printStackTrace();
    }

  }

}
