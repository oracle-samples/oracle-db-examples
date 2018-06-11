/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/**
 * DESCRIPTION
 *
 * A simple illustration of CRUD operation using the Statement object.
 */
import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.Scanner;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.pool.OracleDataSource;


public class StatementSample {

  private static final int USER_OPTION_SELECTALL = 1;
  private static final int USER_OPTION_SELECTONE = 2;
  private static final int USER_OPTION_INSERT = 3;
  private static final int USER_OPTION_UPDATE = 4;
  private static final int USER_OPTION_DELETE = 5;
  private static final int USER_OPTION_EXIT = 0;

  private static final String SQL_INSERT = "INSERT INTO EMP (EMPNO, ENAME, JOB, HIREDATE, SAL) VALUES(%d, '%s', '%s', TO_DATE('%s', 'yyyy/mm/dd'), %f)";

  private static final String SQL_UPDATE
     = "UPDATE EMP SET ENAME = '%s', JOB = '%s', HIREDATE = "
         + "TO_DATE('%s', 'yyyy/mm/dd'), SAL = %f WHERE EMPNO = %d";

  private static final String SQL_DELETE = "DELETE FROM EMP WHERE EMPNO = %d";
  private static final String SQL_SELECT_ALL = "SELECT * FROM EMP";
  private static final String SQL_SELECT_ONE = "SELECT * FROM EMP WHERE EMPNO = %d";




  private static final String DEFAULT_USER = "myuser";
  private static final String DEFAULT_URL
      = "jdbc:oracle:thin:@//myhost:1521/myservice";

  private final String user;
  private final String password;
  private final String url;

  /**
   * Creates an StatementDemo instance with the given details.
   * @param user
   * @param pwd
   * @param url
   */
  private StatementSample(String user, String pwd, String url) {
    this.user = user;
    this.password = pwd;
    this.url = url;
  }

  /**
   * Get a connection from the Oracle Database.
   * and performs CRUD operation based on the user input.
   * @throws SQLException
   */
  private void startDemo() throws SQLException {
    OracleConnection connection = getConnection();
    try {
      // loops forever until the user choose to exit.
      while (true) {
        int userOption = getUserOption();
        switch(userOption) {
        case USER_OPTION_SELECTONE :
          selectOne(connection);
          break;
        case USER_OPTION_SELECTALL :
          selectAll(connection);
          break;
        case USER_OPTION_INSERT :
          insert(connection);
          break;
        case USER_OPTION_UPDATE :
          update(connection);
          break;
        case USER_OPTION_DELETE :
          delete(connection);
          break;
        case USER_OPTION_EXIT :
          show("Bye !!");
          return;
         default :
           show("Invalid option : " + userOption);
        }
      }
    }
    finally {
      connection.close();
    }
  }

  /**
   * Creates an OracleConnection instance and return it.
   * @return oracleConnection
   * @throws SQLException
   */
  private OracleConnection getConnection() throws SQLException {
    OracleDataSource ods = new OracleDataSource();
    ods.setUser(user);
    ods.setPassword(password);
    ods.setURL(url);
    return (OracleConnection)ods.getConnection();
  }

  /**
   * Gets employee details from the user and insert into
   * the Employee table.
   * @param connection
   */
  private void insert(OracleConnection connection) {
    try(Statement stmt = connection.createStatement()) {
     Employee employee = getEmployeeFromConsole();
     if(employee == null) {
       showError("Unable to get employee details.");
       return;
     }
     String insertSQL = String.format(SQL_INSERT, employee.getId(),
         employee.getName(), employee.getDesignation(),
         employee.getJoiningDate(), employee.getSalary());
     boolean status = stmt.execute(insertSQL);
     show("Insert successfull !!");
    }
    catch(SQLException sqle) {
      showError(sqle.getMessage());
    }
  }

  /**
   * Gets employee details from the user and update row in
   * the Employee table with the new details.
   * @param connection
   */
  private void update(OracleConnection connection) {
    try(Statement stmt = connection.createStatement()) {
      Employee employee = getEmployeeFromConsole();
      if(employee == null) {
        showError("Unable to get employee details.");
        return;
      }
      String updateSQL = String.format(SQL_UPDATE,
          employee.getName(), employee.getDesignation(),
          employee.getJoiningDate(), employee.getSalary(),
          employee.getId());
      int noOfRecordsUpdated = stmt.executeUpdate(updateSQL);
      show("Number of records updated : " + noOfRecordsUpdated);
     }
     catch(SQLException sqle) {
       showError(sqle.getMessage());
     }
  }

  /**
   * Gets the employee id from the user and deletes the employee
   * row from the employee table.
   * @param connection
   */
  private void delete(OracleConnection connection) {
    try(Statement stmt = connection.createStatement()) {
      int employeeID = getEmployeeIDFromConsole();
      String deleteSQL = String.format(SQL_DELETE,employeeID);
      int noOfRecordsDeleted = stmt.executeUpdate(deleteSQL);
      show("Number of records deleted : " + noOfRecordsDeleted);
     }
     catch(SQLException sqle) {
       showError(sqle.getMessage());
     }
  }

  /**
   * Gets the employee id from the user and retrieve the specific
   * employee details from the employee table.
   * @param connection
   */
  private void selectOne(OracleConnection connection) {
    int empId = getEmployeeIDFromConsole();
    try(Statement stmt = connection.createStatement()) {
      final String selectSQL = String.format(SQL_SELECT_ONE, empId);
      ResultSet rs = stmt.executeQuery(selectSQL);
      if(rs.next()) {
        Employee emp = new Employee(rs.getInt("EMPNO"),
            rs.getString("ENAME"), rs.getString("JOB"),
            rs.getString("HIREDATE"), rs.getDouble("SAL"));
        emp.print();
      }
      else {
        show("No records found for the employee id : " + empId);
      }
    }
    catch(SQLException sqle) {
      showError(sqle.getMessage());
    }
  }

  /**
   * Selects all the rows from the employee table.
   * @param connection
   */
  private void selectAll(OracleConnection connection) {
    try(Statement stmt = connection.createStatement()) {
      ResultSet rs = stmt.executeQuery(SQL_SELECT_ALL);
      while(rs.next()) {
        Employee emp = new Employee(rs.getInt("EMPNO"),
            rs.getString("ENAME"), rs.getString("JOB"),
            rs.getString("HIREDATE"), rs.getDouble("SAL"));
        emp.print();
      }
    }
    catch(SQLException sqle) {
      showError(sqle.getMessage());
    }
  }

  // Start the main with the command "java StatementDemo -u "<user>" -l "<URL>"
  public static void main(String args[]) throws SQLException, IOException {
    // Gets the URL and USER value from command line arguments
    String url = getCmdOptionValue(args, "-l", DEFAULT_URL);
    String user = getCmdOptionValue(args, "-u", DEFAULT_USER);

    // DB user's Password must be entered
    String pwd = readPassword(" Password for " + user + ": ");

    StatementSample demo = new StatementSample(user, pwd, url);
    demo.startDemo();
  }

  private static String readPassword(String prompt) throws IOException {
    if (System.console() == null) {
      BufferedReader r = new BufferedReader(new InputStreamReader(System.in));
      System.out.print(prompt);
      return r.readLine();
    }
    else {
      return new String(System.console().readPassword(prompt));
    }
  }

  // Get specified option value from command-line, or use default value
  private static String getCmdOptionValue(String args[], String optionName,
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
            show("No value for Option " + optionName + ", use default.");
            argValue = defaultVal;
          }
          found = true;
        }
      }

      if (!found) {
        show("No Option " + optionName + " specified, use default.");
        argValue = defaultVal;
      }
    }
    catch (Exception e) {
      showError("getOptionValue" + e.getMessage());
    }
    return argValue;
  }

  /**
   * Get the user option to perform the table operation.
   *
   * @return
   */
  private static int getUserOption() {
    int userOption = -1;
    try {
      Scanner scanner = new Scanner(System.in);
      System.out.println(
          "1 - Select All, 2 - Select One, 3 - Insert, 4 - Update, 5 - Delete, 0 - Exit");
      System.out.println("Enter Option :");
      userOption = Integer.parseInt(scanner.nextLine());
    }
    catch (Exception e) {
      /* Ignore exception */
    }
    return userOption;
  }

  /**
   * An utility method to get the employee details from the user.
   *
   * @return employeeObj
   */
  private static Employee getEmployeeFromConsole() {
    Employee empObj = null;
    ;
    try {
      Scanner scanner = new Scanner(System.in);
      System.out.println("Enter Employee Details");
      System.out.println("ID : ");
      int id = Integer.parseInt(scanner.nextLine());
      System.out.println("Name : ");
      String name = scanner.nextLine();
      System.out.println("Designation : ");
      String designation = scanner.nextLine();
      System.out.println("Joining Date(yyyy/mm/dd) : ");
      String joiningDate = scanner.nextLine();
      System.out.println("Salary : ");
      double salary = Double.parseDouble(scanner.nextLine());
      empObj = new Employee(id, name, designation, joiningDate, salary);
    }
    catch (Exception e) {
      /* Ignore exception */
    }
    return empObj;
  }

  /**
   * An utility method to get the employee id from the user.
   *
   * @return employeeID
   */
  private static int getEmployeeIDFromConsole() {
    int empId = -1;
    try {
      Scanner scanner = new Scanner(System.in);
      System.out.println("Enter Employee ID :");
      empId = Integer.parseInt(scanner.nextLine());
    }
    catch (Exception e) {
      /* Ignore exception */
    }
    return empId;
  }

  private static void show(String msg) {
    System.out.println(msg);
  }

  private static void showError(String msg) {
    System.out.println("Error : " + msg);
  }

  /**
   * A simple class to represent the employee table structure
   * An instance of this represents a row in employee table.
   */
  private static class Employee {
    private int id;
    private String name;
    private String designation;
    private String joiningDate;
    private double salary;

    Employee(int id, String name, String designation, String joiningDate,
        double salary) {
      super();
      this.id = id;
      this.name = name;
      this.designation = designation;
      this.joiningDate = joiningDate;
      this.salary = salary;
    }

    int getId() {
      return id;
    }

    String getName() {
      return name;
    }

    String getDesignation() {
      return designation;
    }

    String getJoiningDate() {
      return joiningDate;
    }

    double getSalary() {
      return salary;
    }

    void print() {
      show(
          "/----------------------------------------------------------------/");
      show("ID          : " + id);
      show("NAME        : " + name);
      show("Designation : " + designation);
      show("Joining Date: " + joiningDate);
      show("Salary      : " + salary);
      show(
          "/----------------------------------------------------------------/");
    }

  }

}
