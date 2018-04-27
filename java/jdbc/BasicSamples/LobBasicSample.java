/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
   DESCRIPTION
   
    Various lob operations sample.
    To run the sample, you must enter the DB user's password from the 
    console, and optionally specify the DB user and/or connect URL on 
    the command-line. You can also modify these values in this file 
    and recompile the code. 
      java LobBasic -l <url> -u <user> 

   NOTES
   Sample uses books.txt and books.png from current directory.

 */

import java.sql.Connection;
import java.sql.NClob;
import java.sql.Statement;
import java.sql.Types;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Blob;
import java.sql.Clob;
import java.io.BufferedReader;
import java.io.ByteArrayInputStream;
import java.io.File;
import java.io.FileInputStream;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.Reader;
import java.io.Writer;
import java.text.NumberFormat;

import oracle.jdbc.internal.OracleStatement;
import oracle.jdbc.pool.OracleDataSource;
import oracle.sql.CLOB;

/**
 * 
 * Shows dealing with the various LOB data types. Shows how to add a row to a
 * table that has a LOB column. Shows the LOB 2 LONG code path with
 * defineColumnType, LOB prefetch (tune the size). Shows how to create a temp
 * lob.
 * 
 * @author igarish
 *
 */
public class LobBasicSample {
  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  // Table name used in this sample
  // Sample truncates the table and show lob operations
  private final String TABLE_NAME = "LOB_JDBC_SAMPLE";

  // Lob read/write chunk buffer size
  private final int CHUNK_BUFFER_SIZE = 1024;

  // Connection object for various lob operations.
  // Sample uses only one connection for all lob
  // operations in this demo program.
  private Connection conn;

  /**
   * Entry point of the sample.
   * 
   * @param args
   *          Command line arguments. Supported command line options: -l <url>
   *          -u <user>
   * @throws Exception
   */
  public static void main(String args[]) throws Exception {
    LobBasicSample lobBasic = new LobBasicSample();

    getRealUserPasswordUrl(args);

    // Get connection and initialize schema.
    lobBasic.setup();

    // Shows clob operations
    lobBasic.clobSample();

    // Shows clob operations with an empty clob
    lobBasic.clobSampleWithEmptyClob();

    // Shows blob operations
    lobBasic.blobSample();

    // Shows blob operations with an empty blob
    lobBasic.blobSampleWithEmptyBlob();

    // Shows nclob operations
    lobBasic.nclobSample();

    // Shows temporary clob operations
    lobBasic.temporaryClobSample();

    // Fetch a CLOB as a LONG
    lobBasic.clobAsLongSample();

    // Shows how to specify lob prefetch size to fine tune
    // clob performance.
    lobBasic.clobSampleWithLobPrefetchSize();

    // Drop table and disconnect from the database.
    lobBasic.cleanup();
  }

  // Gets connection to the database and truncate the table
  void setup() throws SQLException {
    conn = getConnection();
    truncateTable();
    conn.setAutoCommit(false);
  }

  // Truncates the table and disconnect from the database
  void cleanup() throws SQLException {
    if (conn != null) {
      truncateTable();
      conn.close();
      conn = null;
    }
  }

  // Shows how to create a Clob, insert data in the Clob,
  // retrieves data from the Clob.
  void clobSample() throws Exception {
    show("======== Clob Sample ========");
    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, CLOB_DATA) VALUES (1, ?)")) {
      // Creates and fill data in the clob
      Clob clob = conn.createClob();
      clob.setString(1, "Book Title - Java for Dummies");

      // Insert clob data in the column of a table.
      pstmt.setClob(1, clob);
      pstmt.execute();
      conn.commit();

      // Get data from the clob column.
      executeClobQuery(1);
    }
  }

  // Shows how to create an empty Clob, insert data in the Clob,
  // retrieves data from the Clob.
  void clobSampleWithEmptyClob() throws Exception {
    show("======== Clob Sample with an empty clob ========");
    // Creates an empty clob in a table then update it with actual data.
    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, CLOB_DATA) VALUES (2, empty_clob())")) {
      pstmt.execute();

      try (ResultSet rset = pstmt.executeQuery(
          "SELECT CLOB_DATA FROM " + TABLE_NAME + " WHERE LOB_ID=2 FOR UPDATE")) {
        while (rset.next()) {
          Clob c = rset.getClob(1);

          // Fill clob data from a file and update it in the table.
          readFileAndUpdateClobData(c, "books.txt");
        }
      }

      conn.commit();

      // Get data from the clob column
      executeClobQuery(2);
    }
  }

  // Shows how to insert binary stream data in the Blob,
  // retrieves data from the Blob.
  void blobSample() throws Exception {
    show("======== Blob Sample ========");

    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, BLOB_DATA) VALUES (3, ?)")) {
      byte[] data = { 1, 2, 3, 77, 80, 4, 5 };

      // Insert binary input stream data in the Blob
      pstmt.setBlob(1, new ByteArrayInputStream(data));
      pstmt.execute();
      conn.commit();

      // Get data from the blob column.
      executeBlobQuery(3);
    }
  }

  // Shows how to create an empty Blob, insert data in the Blob,
  // retrieves data from the Blob.
  void blobSampleWithEmptyBlob() throws Exception {
    show("======== Blob Sample with an empty blob ========");

    // Creates an empty blob in a table then update it with actual data.
    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, BLOB_DATA) VALUES (4, empty_blob())")) {
      pstmt.execute();

      try (ResultSet rset = pstmt.executeQuery(
          "SELECT BLOB_DATA FROM " + TABLE_NAME + " WHERE LOB_ID=4 FOR UPDATE")) {
        while (rset.next()) {
          Blob b = rset.getBlob(1);

          // Fill blob data from a file and update it in the table.
          readFileAndUpdateBlobData(b, "books.png");
        }
      }

      conn.commit();

      // Get data from the blob column
      executeBlobQuery(4);
    }
  }

  // Shows how to create a NClob, insert data in the NClob,
  // retrieves data from the NClob.
  void nclobSample() throws Exception {
    show("======== Nclob Sample ========");

    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, NCLOB_DATA) VALUES (5, ?)")) {
      // Creates and fill data in the nclob
      NClob nclob = conn.createNClob();
      nclob.setString(1, "Book Title - Oracle \u00A9 for Dummies ");

      // Insert nclob data in the column of a table.
      pstmt.setNClob(1, nclob);
      pstmt.execute();
      conn.commit();

      // Get data from the nclob column.
      executeNClobQuery(5);
    }
  }

  // You can use temporary LOBs to store transient data. The data is stored in
  // temporary
  // table space rather than regular table space. You should free temporary LOBs
  // after you
  // no longer need them. If you do not, then the space the LOB consumes in
  // temporary
  // table space will not be reclaimed.
  //
  // Shows how to create a temporary CLOB, fill data in the temporary CLOB,
  // insert temporary CLOB data in the table.
  void temporaryClobSample() throws Exception {
    show("======== Temporary Clob Sample ========");

    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, CLOB_DATA) VALUES (6, ?)")) {
      // Creates and fill data in a temporary clob
      Clob tempClob = CLOB.createTemporary(conn, false, CLOB.DURATION_SESSION);
      tempClob.setString(1, "Book Title - JDBC for Dummies");

      // Insert temporary CLOB data in the column of a table.
      pstmt.setClob(1, tempClob);
      pstmt.execute();
      conn.commit();

      // Check whether the CLOB is temporary or regular CLOB.
      boolean isTempCLOB = CLOB.isTemporary((CLOB) tempClob);
      show("CLOB.isTemporary: " + isTempCLOB);

      // Free temporary CLOB
      CLOB.freeTemporary((CLOB) tempClob);

      // Get data from the clob column.
      executeClobQuery(6);
    }
  }

  // Fetch a CLOB as a LONG
  void clobAsLongSample() throws Exception {
    show("======== Clob as Long Sample ========");

    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, CLOB_DATA) VALUES (7, ?)")) {
      // Creates and fill data in the clob
      Clob clob = conn.createClob();
      clob.setString(1, "Book Title - JNI for Dummies");

      // Insert clob data in the column of a table.
      pstmt.setClob(1, clob);
      pstmt.execute();
      conn.commit();

      // Get data from the clob column as if it's LONG type.
      executeClobAsLongQuery(7);
    }
  }

  // Shows how to set lob prefetch size,
  // while retrieving clob data to reduce round trips to the server.
  void clobSampleWithLobPrefetchSize() throws Exception {
    show("======== Clob Sample with LobPrefetchSize ========");

    try (PreparedStatement pstmt = conn.prepareStatement(
        "INSERT INTO " + TABLE_NAME + " (LOB_ID, CLOB_DATA) VALUES (8, ?)")) {
      // Creates and fill data in the clob
      Clob clob = conn.createClob();
      clob.setString(1, "Book Title - Linux for Dummies");

      // Insert clob data in the column of a table.
      pstmt.setClob(1, clob);
      pstmt.execute();
      conn.commit();

      // Sets lob preftech size and gets data from the clob column
      executeClobQueryWithLobPrefetchSize(8);
    }
  }

  // Execute a query to get the clob column data.
  // Iterate through the result.
  private void executeClobQuery(int id) throws Exception {
    try (PreparedStatement pstmt = conn
        .prepareStatement("SELECT CLOB_DATA FROM " + TABLE_NAME + " WHERE LOB_ID=?")) {

      pstmt.setInt(1, id);
      try (ResultSet rset = pstmt.executeQuery()) {
        show("LOB_ID = " + id);
        while (rset.next()) {
          Clob c = rset.getClob(1);

          getAndDisplayClobData("CLOB_DATA  = ", c);
        }
      }
    }

  }

  // Get the clob data as a stream.
  private void getAndDisplayClobData(String message, Clob clob)
      throws Exception {
    // Get a character stream of a clob
    try (Reader clobStream = clob.getCharacterStream()) {
      // Buffer to read chunk of data
      char[] buffer = new char[CHUNK_BUFFER_SIZE];
      int length = 0;

      showln(message);

      // Loop for the reading of clob data in chunks.
      while ((length = clobStream.read(buffer)) != -1)
        showln(new String(buffer, 0, length));

      show("");
    }
  }

  // Read data from a text file and insert it in to the clob column
  private void readFileAndUpdateClobData(Clob clob, String fileName)
      throws Exception {
    // File reader
    File file = new File(fileName);
    try (FileInputStream fileInputStream = new FileInputStream(file)) {
      try (InputStreamReader inputStreamReader = new InputStreamReader(
          fileInputStream)) {
        try (BufferedReader bufferedReader = new BufferedReader(
            inputStreamReader)) {
          // Buffer to read/write chunk of data
          char[] buffer = new char[CHUNK_BUFFER_SIZE];
          int charsRead = 0;

          // Get a clob writer
          try (Writer writer = clob.setCharacterStream(1L)) {
            // Loop for reading of chunk of data and then write into the clob.
            while ((charsRead = bufferedReader.read(buffer)) != -1) {
              writer.write(buffer, 0, charsRead);
            }
          }
        }
      }
    }
  }

  // Execute a query to get the blob column data.
  // Iterate through the result.
  private void executeBlobQuery(int id) throws Exception {
    try (PreparedStatement pstmt = conn
        .prepareStatement("SELECT BLOB_DATA FROM " + TABLE_NAME + " WHERE LOB_ID=?")) {
      pstmt.setInt(1, id);
      try (ResultSet rset = pstmt.executeQuery()) {
        show("LOB_ID = " + id);
        while (rset.next()) {
          Blob b = rset.getBlob(1);

          getAndDisplayBlobData("BLOB_DATA  = ", b);
        }
      }
    }
  }

  // Get the blob data as a stream.
  private void getAndDisplayBlobData(String message, Blob blob)
      throws Exception {
    // Get a binary stream of a blob
    try (InputStream blobStream = blob.getBinaryStream()) {
      // Buffer to read chunk of data
      byte[] buffer = new byte[CHUNK_BUFFER_SIZE];
      int length = 0;
      long totalLength = 0;

      NumberFormat format = NumberFormat.getInstance();
      format.setMinimumIntegerDigits(2);
      format.setGroupingUsed(false);

      // Loop for the reading of blob data in chunks.
      while ((length = blobStream.read(buffer)) != -1) {
        if (totalLength == 0 && length > 25)
          show("First 25 bytes of a Blob column");

        for (int i = 0; i < length; i++) {
          int b = (int) buffer[i] & 0XFF;
          if (totalLength == 0 && i < 25)
            showln(format.format((long) b) + " ");
          else
            break; // We are not consuming more than 25 bytes for demo purpose.
        }

        totalLength += length;
      }

      show("");

      if (totalLength > 25)
        show("Total blob data length:" + totalLength);
    }
  }

  // Read data from a binary file and insert it in to the blob column
  private void readFileAndUpdateBlobData(Blob blob, String fileName)
      throws Exception {
    // File reader
    File file = new File(fileName);
    try (FileInputStream fileInputStream = new FileInputStream(file)) {
      // Buffer to read/write chunk of data
      byte[] buffer = new byte[CHUNK_BUFFER_SIZE];
      int bytesRead = 0;

      // Get a blob output stream
      try (OutputStream outstream = blob.setBinaryStream(1L)) {
        // Loop for reading of chunk of data and then write into the blob.
        while ((bytesRead = fileInputStream.read(buffer)) != -1) {
          outstream.write(buffer, 0, bytesRead);
        }
      }
    }
  }

  // Execute a query to get the nclob column data.
  // Iterate through the result.
  private void executeNClobQuery(int id) throws Exception {
    try (PreparedStatement pstmt = conn
        .prepareStatement("SELECT NCLOB_DATA FROM " + TABLE_NAME + " WHERE LOB_ID=?")) {
      pstmt.setInt(1, id);
      try (ResultSet rset = pstmt.executeQuery()) {
        show("LOB_ID = " + id);
        while (rset.next()) {
          NClob n = rset.getNClob(1);

          getAndDisplayNClobData("NCLOB_DATA  = ", n);
        }
      }
    }
  }

  // Get the nclob data as a stream.
  private void getAndDisplayNClobData(String message, NClob nclob)
      throws Exception {
    // Get a character stream of a nclob
    try (Reader nclobStream = nclob.getCharacterStream()) {
      // Buffer to read chunk of data
      char[] buffer = new char[CHUNK_BUFFER_SIZE];
      int length = 0;

      showln(message);

      // Loop for the reading of nclob data in chunks.
      while ((length = nclobStream.read(buffer)) != -1)
        showln(new String(buffer, 0, length));

      show("");
    }
  }

  // Execute a query to get the clob column data.
  // Iterate through the result as LONG type.
  private void executeClobAsLongQuery(int id) throws Exception {
    try (PreparedStatement pstmt = conn
        .prepareStatement("SELECT CLOB_DATA FROM " + TABLE_NAME + " WHERE LOB_ID=?")) {
      // Fetch LOB data as LONG.
      // LOB data can be read using the same streaming mechanism as for LONG RAW
      // and LONG data.
      // This produces a direct stream on the data as if it were a LONG RAW or
      // LONG column.
      // This technique is limited to Oracle Database 10g release 1 (10.1) and
      // later.
      // The benefit of fetching a CLOB as a LONG (or a BLOB as a LONG_RAW) is
      // that the data
      // will be inlined in the data row that is fetched which may become handy
      // when the locator
      // is not needed and you just need to read the data into a stream.
      // The downside of it is that you don't get the locator and the rows are
      // fetched one by one.
      // The LOB prefetch gives better benefits such as being able to fetch
      // multiple rows in one single roundtrip,
      // getting the length of the LOB immediately and getting the locator.
      // Overall relying on LOB prefetch is always preferable compared to the
      // LOB to LONG technique.
      ((OracleStatement) pstmt).defineColumnType(2, Types.LONGVARBINARY);

      pstmt.setInt(1, id);
      try (ResultSet rset = pstmt.executeQuery()) {
        show("LOB_ID = " + id);
        while (rset.next()) {
          String c = rset.getString(1);

          show("CLOB_DATA as LONG = " + c);
        }
      }
    }
  }

  // If you select LOB columns into a result set, some or all of the data is
  // prefetched to the client, when the locator is fetched. It saves the first
  // roundtrip to
  // retrieve data by deferring all preceding operations until fetching from the
  // locator.
  //
  // The prefetch size is specified in bytes for BLOBs and in characters for
  // CLOBs. It can be
  // specified by setting the connection property
  // oracle.jdbc.defaultLobPrefetchSize.
  // The value of this property can be overridden at statement level by using,
  // oracle.jdbc.OracleStatement.setLobPrefetchSize(int) method.
  //
  // The default prefetch size is 4000.
  //
  // Execute a query to get the clob column data.
  // Iterate through the result.
  private void executeClobQueryWithLobPrefetchSize(int id) throws Exception {
    try (PreparedStatement pstmt = conn
        .prepareStatement("SELECT CLOB_DATA FROM " + TABLE_NAME + " WHERE LOB_ID=?")) {
      // Fine tune lob prefetch size to reduce number of round trips.
      ((OracleStatement) pstmt).setLobPrefetchSize(5000);

      pstmt.setInt(1, id);
      try (ResultSet rset = pstmt.executeQuery()) {
        show("LOB_ID = " + id);
        while (rset.next()) {
          Clob c = rset.getClob(1);

          getAndDisplayClobData("CLOB_DATA  = ", c);
        }
      }
    }
  }

  // ==============================Utility Methods==============================

  private void truncateTable() throws SQLException {
    try (Statement stmt = conn.createStatement()) {
      String sql = "TRUNCATE TABLE " + TABLE_NAME;
      stmt.execute(sql);
    }
  }

  private Connection getConnection() throws SQLException {
    // Create an OracleDataSource instance and set properties
    OracleDataSource ods = new OracleDataSource();
    ods.setUser(user);
    ods.setPassword(password);
    ods.setURL(url);

    return ods.getConnection();
  }

  static void getRealUserPasswordUrl(String args[]) throws Exception {
    // URL can be modified in file, or taken from command-line
    url = getOptionValue(args, "-l", DEFAULT_URL);

    // DB user can be modified in file, or taken from command-line
    user = getOptionValue(args, "-u", DEFAULT_USER);

    // DB user's password can be modified in file, or explicitly entered
    readPassword(" Password for " + user + ": ");
  }

  // Get specified option value from command-line, or use default value
  static String getOptionValue(String args[], String optionName,
      String defaultVal) {
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
    if (System.console() == null) {
      BufferedReader r = new BufferedReader(new InputStreamReader(System.in));
      showln(prompt);
      password = r.readLine();
    } else {
      char[] pchars = System.console().readPassword("\n[%s]", prompt);
      if (pchars != null) {
        password = new String(pchars);
        java.util.Arrays.fill(pchars, ' ');
      }
    }
  }

  private static void show(String msg) {
    System.out.println(msg);
  }

  // Show message line without new line
  private static void showln(String msg) {
    System.out.print(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.out.println(msg + " hit error: " + exc.getMessage());
  }
}

/*
 * ==================================== Expected Output
 * ====================================
 * 
 * ======== Clob Sample ======== LOB_ID = 1 CLOB_DATA = Book Title - Java for Dummies
 * ======== Clob Sample with an empty clob ======== LOB_ID = 2 CLOB_DATA = { "books": [ {
 * "isbn": "9781593275846", "title": "Eloquent JavaScript, Second Edition",
 * "subtitle": "A Modern Introduction to Programming", "author":
 * "Marijn Haverbeke", "published": "2014-12-14T00:00:00.000Z", "publisher":
 * "No Starch Press", "pages": 472, "description":
 * "JavaScript lies at the heart of almost every modern web application, from social apps to the newest browser-based games. Though simple for beginners to pick up and play with, JavaScript is a flexible, complex language that you can use to build full-scale applications."
 * , "website": "http://eloquentjavascript.net/" }, { "isbn": "9781449331818",
 * "title": "Learning JavaScript Design Patterns", "subtitle":
 * "A JavaScript and jQuery Developer's Guide", "author": "Addy Osmani",
 * "published": "2012-07-01T00:00:00.000Z", "publisher": "O'Reilly Media",
 * "pages": 254, "description":
 * "With Learning JavaScript Design Patterns, you'll learn how to write beautiful, structured, and maintainable JavaScript by applying classical and modern design patterns to the language. If you want to keep your code efficient, more manageable, and up-to-date with the latest best practices, this book is for you."
 * , "website":
 * "http://www.addyosmani.com/resources/essentialjsdesignpatterns/book/" } ] }
 * 
 * ======== Blob Sample ======== LOB_ID = 3 01 02 03 77 80 04 05 ======== Blob
 * Sample with an empty blob ======== LOB_ID = 4 First 25 bytes of a Blob column 137
 * 80 78 71 13 10 26 10 00 00 00 13 73 72 68 82 00 00 00 200 00 00 00 198 08
 * Total blob data length:10422 ======== Nclob Sample ======== LOB_ID = 5 NCLOB_DATA = Book
 * Title - Oracle ? for Dummies ======== Temporary Clob Sample ========
 * CLOB.isTemporary: true LOB_ID = 6 CLOB_DATA = Book Title - JDBC for Dummies ======== Clob
 * as Long Sample ======== LOB_ID = 7 CLOB_DATA as LONG = Book Title - JNI for Dummies
 * ======== Clob Sample with LobPrefetchSize ======== LOB_ID = 8 CLOB_DATA = Book Title -
 * Linux for Dummies
 * 
 */
