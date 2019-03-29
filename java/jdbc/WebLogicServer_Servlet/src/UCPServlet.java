package com.jdbc;

import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import oracle.ucp.admin.UniversalConnectionPoolManagerImpl;
import oracle.ucp.jdbc.PoolDataSource;

/**
 * Servlet implementation class UCPServlet
 */
@WebServlet("/UCPServlet")
public class UCPServlet extends HttpServlet {
  private static final long serialVersionUID = 1L;

    /**
     * @see HttpServlet#HttpServlet()
     */
    public UCPServlet() {
        super();
    }

  /**
   * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
   */
  protected void doGet(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException {
    PrintWriter out = response.getWriter();

    out.println("Servlet to test ATP using UCP");
    Connection conn = null;
    try {
      // Get a context for the JNDI look up
      PoolDataSource pds = getPoolInstance();
      conn = pds.getConnection();

      // Prepare a statement to execute the SQL Queries.
      Statement statement = conn.createStatement();
      // Create table EMP
      statement.executeUpdate("create table EMP(EMPLOYEEID NUMBER,"
          + "EMPLOYEENAME VARCHAR2 (20))");
      out.println("New table EMP is created");
      // Insert some records into the table EMP
      statement.executeUpdate("insert into EMP values(1, 'Jennifer Jones')");
      statement.executeUpdate("insert into EMP values(2, 'Alex Debouir')");
      out.println("Two records are inserted.");

      // Update a record on EMP table.
      statement.executeUpdate("update EMP set EMPLOYEENAME='Alex Deborie'"
          + " where EMPLOYEEID=2");
      out.println("One record is updated.");

      // Verify the table EMP
      ResultSet resultSet = statement.executeQuery("select * from EMP");
      out.println("\nNew table EMP contains:");
      out.println("EMPLOYEEID" + " " + "EMPLOYEENAME");
      out.println("--------------------------");
      while (resultSet.next()) {
        out.println(resultSet.getInt(1) + " " + resultSet.getString(2));
      }
      out.println("\nSuccessfully tested a connection to ATP using UCP");
    }
    catch (Exception e) {
      response.setStatus(500);
      response.setHeader("Exception", e.toString());
      out.print("\n Web Request failed");
      out.print("\n "+e.toString());
      e.printStackTrace();
    }
    finally {
      // Clean-up after everything
      try (Statement statement = conn.createStatement()) {
        statement.execute("drop table EMP");
        conn.close();
      }
      catch (SQLException e) {
        System.out.println("UCPServlet - "
            + "doSQLWork()- SQLException occurred : " + e.getMessage());
      }
    }
  }

  /* Get the appropriate datasource */
  private PoolDataSource getPoolInstance() throws NamingException {
    Context ctx = new InitialContext();

    // Look up a data source
    javax.sql.DataSource ds
          = (javax.sql.DataSource) ctx.lookup ("orclatp_ds");
    PoolDataSource pds=(PoolDataSource)ds;

    return pds;
  }

  public void destroy() {
    try {

      UniversalConnectionPoolManagerImpl.getUniversalConnectionPoolManager()
          .destroyConnectionPool(getPoolInstance().getConnectionPoolName());
      System.out.println("Pool Destroyed");
    } catch (Exception e) {
      System.out.println("destroy pool got Exception:");
      e.printStackTrace();
    }

  }

  /**
    * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
  */
  protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {

  }

}
