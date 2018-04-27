/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/
/**
 * DESCRIPTION
 *
 * This code sample illustrates the usage of below Oracle column data types -
 * <p>
 * DATE, TIMESTAMP, TIMESTAMP WITH TIME ZONE and TIMESTAMP WITH LOCAL TIME ZONE
 * </p>
 * The code sample creates a simple table with these data types and performs
 * insert, update, and retrieval operation on the table.
 * <p>
 * It is required that applications have Oracle JDBC driver jar (ojdbc8.jar) in
 * the class-path, and that the database backend supports SQL (this sample uses
 * an Oracle Database).
 * </p>
 * <p>
 * To run the sample, you must enter the DB user's password from the console,
 * and optionally specify the DB user and/or connect URL on the command-line.
 * You can also modify these values in this file and recompile the code.
 * </p>
 *
 * java DateTimeStampSample -l <url> -u <user>
 *
 */
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.Date;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.SQLType;
import java.sql.Statement;
import java.sql.Timestamp;
import java.time.LocalDateTime;
import java.time.ZonedDateTime;

import oracle.jdbc.OracleType;
import oracle.jdbc.pool.OracleDataSource;

public class DateTimeStampSample {

  // Either modify user and url values to point your DB or
  // provide these values using command line arguments.
  private static String user = "myuser";
  private static String password = "mypassword";
  private static String url = "jdbc:oracle:thin:@//myhost:1521/myservice";

  public static void main(String[] args) throws Exception {

    // These 2 can be either default or from command-line
    url = getOptionValue(args, "-l", url);
    user = getOptionValue(args, "-u", user);

    // DB user's Password must be entered
    readPassword(" Enter Password for " + user + ": ");

    DateTimeStampSample demo = new DateTimeStampSample();
    demo.run();
  }

  void run() throws SQLException {
    try (Connection conn = getConnection()) {

      // Truncate the existing table
      truncateTable(conn);

      // employee details
      int empId = 1001;
      Date dateOfBirth = Date.valueOf("1988-09-04");
      LocalDateTime joiningDate = LocalDateTime.now();
      ZonedDateTime dateOfResignation = ZonedDateTime
          .parse("2018-05-09T22:22:22-08:00[PST8PDT]");
      Timestamp dateOfLeaving = Timestamp.valueOf(LocalDateTime.now());
      Employee e = new Employee(empId, dateOfBirth, joiningDate,
          dateOfResignation, dateOfLeaving);
      show("\nInsert employee record into table with id = "+empId);
      insertEmployee(e, conn);

      show("\nEmployee details of employee = " + empId);
      Employee emp = getEmployeeDetails(1001, conn);
      if (emp != null)
        emp.print();

      show("Update the employee details of employee = " + empId);
      updateEmployee(empId, conn);

      show("\nUpdated details of employee = " + empId);
      Employee emp1 = getEmployeeDetails(1001, conn);
      if (emp1 != null)
        emp1.print();

      show("JDBCDateTimeSample demo completes.");
    }

  }

  /**
   * Inserts employee data into table using given connection.
   *
   * @param emp
   *          Employee data
   * @param conn
   *          Connection to be used to insert the employee data.
   * @throws SQLException
   */
  private void insertEmployee(Employee emp, Connection conn)
      throws SQLException {
    final String insertQuery = "INSERT INTO EMP_DATE_JDBC_SAMPLE VALUES(?,?,?,?,?)";
    try (PreparedStatement pstmt = conn.prepareStatement(insertQuery)) {
      SQLType dataType = null;

      pstmt.setInt(1, emp.getId());
      pstmt.setDate(2, emp.getDateOfBirth());
      dataType = OracleType.TIMESTAMP_WITH_LOCAL_TIME_ZONE;
      pstmt.setObject(3, emp.getJoiningDate(), dataType);
      dataType = OracleType.TIMESTAMP_WITH_TIME_ZONE;
      pstmt.setObject(4, emp.getResignationDate(), dataType);
      pstmt.setTimestamp(5, emp.getDateOfLeaving());
      pstmt.executeUpdate();
      show("Employee record inserted successfully.");
    }
  }

  /**
   * Fetches the employee data for given employee id.
   *
   * @param id
   *          Employee id.
   * @param conn
   *          Connection to be used to fetch employee data.
   * @return
   * @throws SQLException
   */
  private Employee getEmployeeDetails(int id, Connection conn)
      throws SQLException {
    final String selectQuery = "SELECT EMP_ID, DATE_OF_BIRTH, DATE_OF_JOINING, "
        + "DATE_OF_RESIGNATION, DATE_OF_LEAVING FROM EMP_DATE_JDBC_SAMPLE WHERE EMP_ID = ?";
    try (PreparedStatement pstmt = conn.prepareStatement(selectQuery)) {
      pstmt.setInt(1, id);
      try (ResultSet rs = pstmt.executeQuery()) {
        if (rs.next()) {
          int employeeId = rs.getInt(1);
          Date datOfBirth = rs.getDate(2);
          LocalDateTime dateOfJoining = rs.getObject(3, LocalDateTime.class);
          ZonedDateTime dateOfResignation = rs
              .getObject(4, ZonedDateTime.class);
          Timestamp dateOfLeaving = rs.getTimestamp(5);
          return new Employee(employeeId, datOfBirth, dateOfJoining,
              dateOfResignation, dateOfLeaving);
        } else {
          show("Employee record not found in the database.");
          return null;
        }
      }

    }
  }

  /**
   * Updates the employee record for given employee id.
   *
   * @param id
   *          Employee id.
   * @param conn
   *          Connection to be used to update employee data.
   * @throws SQLException
   */
  private void updateEmployee(int id, Connection conn) throws SQLException {
    final String updateQuery = "UPDATE EMP_DATE_JDBC_SAMPLE SET DATE_OF_JOINING=? WHERE EMP_ID =?";
    try (PreparedStatement pstmt = conn.prepareStatement(updateQuery)) {
      SQLType dataType = OracleType.TIMESTAMP_WITH_LOCAL_TIME_ZONE;
      pstmt.setObject(1,
          ZonedDateTime.parse("2015-12-09T22:22:22-08:00[PST8PDT]"), dataType);
      pstmt.setInt(2, id);
      int updateCount = pstmt.executeUpdate();
      show("Successfully updated employee details.");
    }
  }

  private void truncateTable(Connection conn) {
    final String sql = "TRUNCATE TABLE EMP_DATE_JDBC_SAMPLE";
    try (Statement st = conn.createStatement()) {
      st.executeQuery(sql);
      show("Table truncated successfully.");
    } catch (SQLException e) {
      showError("Truncate table operation failed.", e);
    }
  }

  static Connection getConnection() throws SQLException {
    OracleDataSource ods = new OracleDataSource();
    ods.setURL(url);
    ods.setUser(user);
    ods.setPassword(password);
    Connection conn = ods.getConnection();
    return conn;
  }

  private static void show(String msg) {
    System.out.println(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.out.println(msg + " hit error: " + exc.getMessage());
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

  /**
   * Reads the password from console.
   *
   * @param prompt
   * @throws Exception
   */
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

  /**
   * A simple class to represent the employee table structure. An instance of
   * this class represents a row in employee table.
   */
  static class Employee {
    private int id;
    private Date dateOfBirth;
    private LocalDateTime joiningDate;
    private ZonedDateTime dateOfResignation;
    private Timestamp dateOfLeaving;

    Employee(int id, Date dateOfBirth, LocalDateTime joiningDate,
        ZonedDateTime dateOfResignation, Timestamp dateOfLeaving) {
      this.id = id;
      this.dateOfBirth = dateOfBirth;
      this.joiningDate = joiningDate;
      this.dateOfResignation = dateOfResignation;
      this.dateOfLeaving = dateOfLeaving;
    }

    int getId() {
      return id;
    }

    Date getDateOfBirth() {
      return this.dateOfBirth;
    }

    LocalDateTime getJoiningDate() {
      return this.joiningDate;
    }

    ZonedDateTime getResignationDate() {
      return this.dateOfResignation;
    }

    Timestamp getDateOfLeaving() {
      return this.dateOfLeaving;
    }

    void print() {
      show("/----------------------------------------------------------------/");
      show("ID                   : " + id);
      show("Date Of Birth        : " + dateOfBirth);
      show("Joining Date         : " + joiningDate);
      show("Resignation Date     : " + dateOfResignation);
      show("Date of Leaving      : " + dateOfLeaving);
      show("/----------------------------------------------------------------/\n");
    }
  }
}
