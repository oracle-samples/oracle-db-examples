import java.io.IOException;
import java.io.PrintWriter;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import javax.sql.DataSource;
import java.sql.DatabaseMetaData;

import javax.naming.Context;
import javax.naming.InitialContext;
import javax.naming.NamingException;
import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class JDBCSample_Servlet
 */
@WebServlet("/JDBCSample_Servlet")
public class JDBCSample_Servlet extends HttpServlet {
  private static final long serialVersionUID = 1L;     
    /**
     * @see HttpServlet#HttpServlet()
     */
    public JDBCSample_Servlet() {
        super();
    }

  /**
   * Method to get a connection to the Oracle Database and perform few 
   * database operations and display the results on a web page. 
   */
  protected void doGet(HttpServletRequest request, HttpServletResponse response)
           throws ServletException, IOException {
    PrintWriter out = response.getWriter();
    out.print("Sample JDBC Servlet");
    try {
      // Get a context for the JNDI look up
      DataSource ds = getDataSource();
      // With AutoCloseable, the connection is closed automatically.
      try (Connection connection = ds.getConnection()) {
        for (int i=0; i<10; i++) {
          out.println("The database user is" 
             + executeBusinessLogicOnDatabase(connection, out));
        }
        out.print("\n Sample JDBC Servlet Request was successful");
        response.setStatus(200);
      }
    } catch (Exception e) {
      response.setStatus(500);
      response.setHeader("Exception", e.toString());
      out.print("\n Web Request failed");
      out.print("\n "+e.toString());
      e.printStackTrace();
    }
  }

 /*
  * Method to create a datasource after the JNDI lookup
  */

  private DataSource getDataSource() throws NamingException {
    Context ctx;
    ctx = new InitialContext();
    Context envContext = (Context) ctx.lookup("java:/comp/env");
    // Look up a data source
    javax.sql.DataSource ds
          = (javax.sql.DataSource) envContext.lookup ("jdbc/orcljdbc_ds");
    return ds;
  }

 /*
  * Method to showcase database operations using the database connection 
  */
  private String executeBusinessLogicOnDatabase(Connection conn, 
    PrintWriter out) throws SQLException {
    // Get the JDBC driver name and version 
    DatabaseMetaData dbmd = conn.getMetaData();       
    out.println("Driver Name: " + dbmd.getDriverName());
    out.println("Driver Version: " + dbmd.getDriverVersion());
    
    String user = null;	
    String query = "select user from dual"; 
    Statement stmt = conn.createStatement(); 
    ResultSet rs = stmt.executeQuery(query); 
    while (rs.next()) { 
     user = rs.getString(1);
    }          
    stmt.close();
    rs.close();
    return user;
  }

  public void destroy() { }
  
}
