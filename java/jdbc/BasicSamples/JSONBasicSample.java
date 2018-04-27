/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/**
 * DESCRIPTION
 *
 * This code sample objective is to show how to use some of the
 * enhancements in JavaScript Object Notation (JSON) support for
 * Oracle Database 12c Release 2 (12.2).
 *
 * This release incorporates significant new features. In this sample
 * we are going to expose the following:
 *
 * <ul>
 * <li>Create tables and constraints on columns for JSON documents
 * using <CODE>ENSURE_JSON</CODE> and <CODE>IS JSON</CODE>
 * directives.</li>
 * <li>Load tables validating those constraints.</li>
 * <li>Use Simple Dot-Notation Access to JSON Data.</li>
 * <li>Use Simple SQL/JSON Path Expressions using
 * <CODE>JSON_VALUE</CODE>.</li>
 * <li>Use Complex SQL/JSON Path Expressions using
 * <CODE>JSON_EXISTS</CODE>.</li>
 * </ul>
 *
 * It is required that applications have Oracle JDBC driver jar on
 * the classpath. This sample is based on Oracle as the database
 * backend.
 *
 * To run the sample, you must enter the DB user's password from the
 * console, and optionally specify the DB user and/or connect URL on
 * the command-line. You can also modify these values in this file
 * and recompile the code.
 *   java JSONBasicSample -l <url> -u <user>
 */

import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

// From Oracle JDBC driver
import oracle.jdbc.pool.OracleDataSource;

public class JSONBasicSample {

  final static String DEFAULT_URL = "jdbc:oracle:thin:@//myhost:myport/myservice";
  final static String DEFAULT_USER = "myuser";
  final static String DEFAULT_PASSWORD = "mypassword";
  final static String CONN_FACTORY_CLASS = "oracle.jdbc.pool.OracleDataSource";

  // You must provide non-default values for ALL 3 to execute the program
  static String url = DEFAULT_URL;
  static String user = DEFAULT_USER;
  static String password = DEFAULT_PASSWORD;

  public static void main(String args[]) throws Exception {

    // The program exits if any of the 3 fields still has default value.
    getRealUserPasswordUrl(args);

    // Run sample.
    JSONBasicSample sample = new JSONBasicSample();
    sample.run();
  }

  private OracleDataSource dataSource = null;
  private Connection connection = null;
  private Statement statement = null;
  private PreparedStatement getSalaryStatement = null;

  private void run() throws Exception {

    // Set up test: open connection/statement to be used through the demo.
    demoSetUp();

    // Test the constraint with an incorrect JSON document.
    // If the SQLException is not caught, show as an error.
    try {
      demoExecute("INSERT INTO JSON_EMP_JDBC_SAMPLE VALUES (SYS_GUID(), SYSTIMESTAMP, '{\"emp\"loyee_number\": 5, \"employee_name\": \"Jack Johnson\"}')");
      showError("Error!. SQLException was expected to be thrown because of bad formatted JSON.", new SQLException());
    } catch (SQLException sqlException) {
      show("Good catch! SQLException was expected to be thrown because of bad formatted JSON.");
    }

    // This is a Simple Dot Notation Query on a column with a JSON document.
    // The return value for a dot-notation query is always a string (data type VARCHAR2) representing JSON data.
    // The content of the string depends on the targeted JSON data, as follows:
    // If a single JSON value is targeted, then that value is the string content, whether it is a JSON scalar, object, or array.
    // If multiple JSON values are targeted, then the string content is a JSON array whose elements are those values.
    demoExecuteAndShow("SELECT em.employee_document.employee_number, em.employee_document.salary FROM JSON_EMP_JDBC_SAMPLE em");

    // This is a Simple Path Notation Query
    // SQL/JSON path expressions are matched by SQL/JSON functions and conditions against JSON data, to select portions of it.
    // Path expressions are analogous to XQuery and XPath expression. They can use wild-cards and array ranges. Matching is case-sensitive.
    demoExecuteAndShow("SELECT JSON_VALUE(employee_document, '$.employee_number') FROM JSON_EMP_JDBC_SAMPLE where JSON_VALUE(employee_document, '$.salary') > 2000");

    // This is a Complex Path Notation Query (employees with at least one son named 'Angie').
    // An absolute simple path expression begins with a dollar sign ($), which represents the path-expression context item.
    // The dollar sign is followed by zero or more path steps.
    // Each step can be an object step or an array step, depending on whether the context item represents a JSON object or a JSON array.
    // The last step of a simple path expression can be a single, optional function step.
    // In all cases, path-expression matching attempts to match each step of the path expression, in turn.
    // If matching any step fails then no attempt is made to match the subsequent steps, and matching of the path expression fails.
    // If matching each step succeeds then matching of the path expression succeeds.
    demoExecuteAndShow("SELECT JSON_VALUE(employee_document, '$.employee_name') FROM JSON_EMP_JDBC_SAMPLE where JSON_EXISTS(employee_document, '$.sons[*]?(@.name == \"Angie\")')");

    // Demo using getSalary for an existing number
    show("Get salary for Jane Doe (employee number:2), "
        + "2010 expected: " + getSalary(2));

    // Demo using getSalary for a non existing number
    show("Get salary for non existing (employee number:5), "
        + "negative value expected: " + getSalary(5));

    // Tear down test: close connections/statements that were used through the demo.
    demoTearDown();
  }

  /**
   * Return an employee's salary using the employee number.
   * If the employee does not exist, a negative value is returned.
   * Demo based on a Path Notation Query in a PreparedStatement.
   *
   * @param employee number.
   * @return employee salary, negative value if not found.
   */
  private double getSalary(long employeeNumber) throws SQLException {

    // Bind parameter (employee number) to the query.
    getSalaryStatement.setLong(1, employeeNumber);

    // Return salary (negative value if not found).
    ResultSet employees = getSalaryStatement.executeQuery();
    if (employees.next()) {
      return employees.getDouble(1);
    } else {
      return -1d;
    }
  }

  private void demoSetUp() throws SQLException {
    dataSource = new OracleDataSource();
    dataSource.setURL(url);
    dataSource.setUser(user);
    dataSource.setPassword(password);
    connection = dataSource.getConnection();
    statement = connection.createStatement();

    // PreparedStatement to return the salary from an employee using the
    // employee number (with Path Notation Query over the document).
    getSalaryStatement = connection.prepareStatement(
        "SELECT JSON_VALUE(employee_document, '$.salary') "
        + "FROM JSON_EMP_JDBC_SAMPLE where JSON_VALUE "
        + "(employee_document, '$.employee_number') = ?");

  }

  private ResultSet demoExecute(String sql) throws SQLException {
    return statement.executeQuery(sql);
  }

  private void demoExecuteAndShow(String sql) throws SQLException {
    ResultSet resultSet = demoExecute(sql);
    final int columnCount = resultSet.getMetaData().getColumnCount();
    while (resultSet.next()) {
      StringBuffer output = new StringBuffer();
      for (int columnIndex = 1; columnIndex <= columnCount; columnIndex++)
        output.append(resultSet.getString(columnIndex)).append("|");
      show(output.toString());
    }
  }

  private void demoTearDown() throws SQLException {
    statement.close();
    getSalaryStatement.close();
    connection.close();
  }

  private static void show(String msg) {
    System.out.println(msg);
  }

  static void showError(String msg, Throwable exc) {
    System.out.println(msg + " hit error: " + exc.getMessage());
  }

  // The program exits if any of the 3 fields still has default value.
  static void getRealUserPasswordUrl(String args[]) throws Exception {
    // URL can be modified in file, or taken from command-line
    url  = getOptionValue(args, "-l", DEFAULT_URL);
    if (DEFAULT_URL.equals(url)) {
      show("\nYou must provide a non-default, working connect URL. Exit.");
      System.exit(1);
    }

    // DB user can be modified in file, or taken from command-line
    user = getOptionValue(args, "-u", DEFAULT_USER);
    if (DEFAULT_USER.equals(user)) {
      show("\nYou must provide a non-default, working DB user. Exit.");
      System.exit(1);
    }

    // DB user's password can be modified in file, or explicitly entered
    readPassword(" Password for " + user + ": ");
    if (DEFAULT_PASSWORD.equals(password)) {
      show("\nYou must provide a non-default, working DB password. Exit.");
      System.exit(1);
    }
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
            show("No value specified for Option " + optionName);
            argValue = defaultVal;
          }
          found = true;
        }
      }

      if (!found) {
        show("No Option " + optionName + " specified");
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
