/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/**
 * DESCRIPTION
 *
 * This is a simple example of how to create, insert, and query SQLXML values. For
 * more info see {@link https://docs.oracle.com/javase/tutorial/jdbc/basics/sqlxml.html},
 * and {@link https://docs.oracle.com/en/database/oracle/oracle-database/12.2/adxdb/intro-to-XML-DB.html}.
 *
 * To run the sample, you must provide non-default and working values
 * for ALL 3 of user, password, and URL. This can be done by either updating
 * this file directly or supplying the 3 values as command-line options
 * and user input. The password is read from console or standard input.
 *   java SQLXMLSample -l <url> -u <user>
 * If you do not update all the defaults, the program proceeds but
 * will hit error when connecting.
 */
 
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.OutputStreamWriter;
import java.io.Writer;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.JDBCType;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLXML;
import java.sql.Statement;
import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import javax.xml.parsers.ParserConfigurationException;
import javax.xml.transform.OutputKeys;
import javax.xml.transform.Transformer;
import javax.xml.transform.TransformerException;
import javax.xml.transform.TransformerFactory;
import javax.xml.transform.dom.DOMSource;
import javax.xml.transform.stream.StreamResult;

import org.w3c.dom.Document;
import org.xml.sax.ContentHandler;
import org.xml.sax.SAXException;
import org.xml.sax.helpers.DefaultHandler;


public class SQLXMLSample {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  /**
   * Create an instance, get the database user password, and run the sample code.
   *
   * @param args command line args
   * @throws Exception if an error occurs
   */
  public static void main(String args[]) throws Exception {
    SQLXMLSample sample = new SQLXMLSample();

    getRealUserPasswordUrl(args);
    sample.run();
  }

  /**
   * Demonstrate the sample code.
   * <ol>
   * <li>drop the sample table to insure the table can be created properly</li>
   * <li>create the sample table</li>
   * <li>insert SQLXML values into the table</li>
   * <li>read the SQLXML values from the table</li>
   * <li>clean up</li>
   * </ol>
   *
   * @throws Exception
   */
  private void run() throws Exception {
    try (Connection conn = DriverManager.getConnection(url, user, password)) {
      truncateTable(conn);
      loadTable(conn);
      queryTable(conn);
      truncateTable(conn);
    }
  }

  /**
   * Clear the sample table with two columns.
   *
   * @param conn a database Connection
   * @throws SQLException
   */
  private void truncateTable(Connection conn) throws SQLException {
    String sql = "TRUNCATE TABLE SQLXML_JDBC_SAMPLE";
    show(sql);
    doSql(conn, sql);
  }

  /**
   * Create SQLXML values and insert them into the sample table. Demonstrates
   * two possible ways to create a SQLXML value. There are others. Uses the
   * generic setObject(int, Object, SQLType) method to set the parameters.
   *
   * @param conn
   * @throws SQLException
   */
  private void loadTable(Connection conn) throws SQLException {
    String insertDml = "INSERT INTO SQLXML_JDBC_SAMPLE (DOCUMENT, ID) VALUES (?, ?)";
    try (PreparedStatement prepStmt = conn.prepareStatement(insertDml)) {

      SQLXML xml = conn.createSQLXML();
      xml.setString("<?xml version=\"1.0\"?>\n" +
                    "               <EMP>\n" +
                    "                  <EMPNO>221</EMPNO>\n" +
                    "                  <ENAME>John</ENAME>\n" +
                    "               </EMP>");

      prepStmt.setObject(1, xml, JDBCType.SQLXML);
      prepStmt.setObject(2, 221, JDBCType.NUMERIC);
      prepStmt.executeUpdate();

      xml = conn.createSQLXML();
      Writer w = xml.setCharacterStream();
      w.write("<?xml version=\"1.0\"?>\n");
      w.write("               <EMP>\n");
      w.write("                  <EMPNO>222</EMPNO>\n");
      w.write("                  <ENAME>Mary</ENAME>\n");
      w.write("               </EMP>\n");
      w.close();

      prepStmt.setObject(1, xml, JDBCType.SQLXML);
      prepStmt.setObject(2, 222, JDBCType.NUMERIC);
      prepStmt.executeUpdate();

    }
    catch (IOException ex) {
      throw new SQLException(ex);
    }
  }

  /**
   * Query the sample table, retrive the SQLXML values and print their contents
   * to stdout. Uses the generic getObject(int, Class) method.
   *
   * @param conn
   * @throws SQLException
   */
  private void queryTable(Connection conn) throws SQLException {
    String query = "SELECT DOCUMENT, ID FROM SQLXML_JDBC_SAMPLE ORDER BY ID";
    try (PreparedStatement pstmt = conn.prepareStatement(query)) {
      ResultSet rs = pstmt.executeQuery();
      while (rs.next()) {
        SQLXML sqlxml = rs.getObject(1, SQLXML.class);
        InputStream binaryStream = sqlxml.getBinaryStream();
        DocumentBuilder parser
                = DocumentBuilderFactory.newInstance().newDocumentBuilder();
        Document result = parser.parse(binaryStream);
        printDocument(result, System.out);
        System.out.println();
      }
    }
    catch (IOException | TransformerException | SAXException | ParserConfigurationException ex) {
      throw new SQLException(ex);
    }
  }


  //
  // Utility methods
  //

  /**
   * Simple code to print an XML Documint to an OutputStream.
   *
   * @param doc an XML document to print
   * @param the stream to print to
   * @throws IOException if an error occurs is writing the output
   * @throws TransformerException if an error occurs in generating the output
   */
  static void printDocument(Document doc, OutputStream out)
    throws IOException, TransformerException {
    TransformerFactory factory = TransformerFactory.newInstance();
    Transformer transformer = factory.newTransformer();
    transformer.setOutputProperty(OutputKeys.ENCODING, "UTF-8");
    transformer.setOutputProperty(OutputKeys.METHOD, "xml");
    transformer.setOutputProperty(OutputKeys.OMIT_XML_DECLARATION, "no");
    transformer.setOutputProperty(OutputKeys.INDENT, "yes");
    transformer.setOutputProperty("{http://xml.apache.org/xslt}indent-amount", "4");

    transformer.transform(new DOMSource(doc),
         new StreamResult(new OutputStreamWriter(out, "UTF-8")));
  }

  static void doSql(Connection conn, String sql) throws SQLException {
    try (Statement stmt = conn.createStatement()) {
      stmt.execute(sql);
    }
  }

  static void trySql(Connection conn, String sql) {
    try {
      doSql(conn, sql);
    }
    catch (SQLException ex) {
      // ignore
    }
  }

  static void show(String msg) {
    System.out.println(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.err.println(msg + " hit error: " + exc.getMessage());
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
