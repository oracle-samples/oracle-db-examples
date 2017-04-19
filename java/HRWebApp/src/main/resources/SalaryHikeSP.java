/* Copyright (c) 2015, Oracle and/or its affiliates. All rights reserved.*/
/*
   DESCRIPTION
     This is a Java class that invokes the SalaryHikeSP stored procedure. 
     
     Step 1: Connect to SQLPLUS using the database USER/PASSWORD. 
             Make sure to have SalaryHikeSP.sql accessible on the 
             client side to execute. 
     Step 2: Run the SQL file after connecting to DB "@SalaryHikeSP.sql" 

   NOTES
    Use JDK 1.6 and above

   MODIFIED    (MM/DD/YY)
    nbsundar    03/23/15 - Creation (kmensah - Contributor)
 */
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.sql.PreparedStatement;
import oracle.jdbc.OracleStatement;
import oracle.jdbc.OracleConnection;

import oracle.jdbc.driver.OracleDriver;
import oracle.jdbc.pool.OracleDataSource;


public class SalaryHikeSP {
  /*
   *  Increment the Salary
   */
  public static ResultSet incrementSalary (int percentIncrease) throws SQLException {
    int updateCount = 0;
    int totalemployees = 0;
    int tier3emp = 0;
    int tier2emp = 0;
    int tier1emp = 0;
    float totalsalary = 0.0f;
    float minsalary = 0.0f;
    float maxsalary = 0.0f;
    float totalbudget = 0.0f;
    float tier3hike = 0.0f;
    float tier2hike = 0.0f;
    float tier1hike = 0.0f;


    // Percentage to divide the salary hike budget into
    // three tiers based on the salary range
    // Tier 1 salary range is 15,001 to 25,000
    float tier1percent = 0.10f;
    // Tier 2 salary range is  7,001 to 15,000
    float tier2percent = 0.30f;
    // Tier 3 salary range is 0 to 7,000
    float tier3percent = 0.60f;

    Connection connection = null;
    ResultSet resultSet = null;
    Statement statement = null;
    PreparedStatement preparedStatement;
    ResultSet rset = null;

    System.out.println("==== Here ===== ");
    String TOTAL_EMP = "SELECT count(EMPLOYEE_ID) from EMPLOYEES";
    String TOTAL_SALARY = "SELECT sum(salary) from EMPLOYEES";
    String MIN_SALARY = "SELECT min(salary) from EMPLOYEES";
    String MAX_SALARY = "SELECT max(salary) from EMPLOYEES";
    String UPDATE_SQL =
        "UPDATE EMPLOYEES SET SALARY = 20000 WHERE EMPLOYEE_ID=100";
    String TIER3_EMP = "SELECT COUNT(EMPLOYEE_ID) from EMPLOYEES WHERE " +
        "salary >= ? and salary < 7000.00";
    String TIER2_EMP =  "SELECT count(EMPLOYEE_ID) from EMPLOYEES " +
        " WHERE SALARY > 7001.00 and SALARY < 15000.00";
    String TIER1_EMP ="SELECT count(EMPLOYEE_ID) from EMPLOYEES " +
        " WHERE SALARY >15001.00 AND SALARY < ?";

    String TIER3_UPDATE ="UPDATE EMPLOYEES SET SALARY = (SALARY + ?)" +
        " WHERE salary > ? " +
        " and salary < 7000.00";
    String TIER2_UPDATE = "UPDATE EMPLOYEES SET SALARY = (SALARY + ? )" +
        " WHERE SALARY > 7001.00 and SALARY < 15000.00 ";
    String TIER1_UPDATE = "UPDATE EMPLOYEES SET SALARY = (SALARY + ?)" +
        " WHERE SALARY > 15001.00 and SALARY < ? ";
    if (percentIncrease <= 0) {
      throw new
          IllegalArgumentException("Invalid percentage provided: " +percentIncrease);
    }
    try {
      connection = new OracleDriver().defaultConnection();
      // Get the total number of employees
      statement = connection.createStatement();
      resultSet = statement.executeQuery(TOTAL_EMP);
      while (resultSet.next()) {
        totalemployees = resultSet.getInt(1);
        System.out.println("Number of employees" + totalemployees);
      }
      // Get the total salary of all employees
      resultSet = statement.executeQuery(TOTAL_SALARY);
      while (resultSet.next()) {
        totalsalary = resultSet.getFloat(1);
        System.out.println("Total salary of all employees: " + totalsalary);
      }
      // Get the minimum salary of all employees
      resultSet = statement.executeQuery(MIN_SALARY);
      while (resultSet.next()) {
        minsalary = resultSet.getFloat(1);
        System.out.println("Minimum salary of all employees: " + minsalary);
      }
      // Get the maximum salary of all employees
      resultSet = statement.executeQuery(MAX_SALARY);
      while (resultSet.next()) {
        maxsalary = resultSet.getFloat(1);
        System.out.println("Maximum salary of all employees: " + maxsalary);
      }
      // Get the budget for the salary rise
      totalbudget = (totalsalary * percentIncrease )/100;
      System.out.println("Total budget for the rise: " + totalbudget);

      // Get the salary increase for the tier3 employees
      // 60% of the total budget is for tier3 employees
      preparedStatement = connection.prepareStatement(TIER3_EMP);
      preparedStatement.setFloat(1,minsalary);
      resultSet = preparedStatement.executeQuery();

      while (resultSet.next()) {
        tier3emp = resultSet.getInt(1);
        if ( tier3emp != 0 ) {
          tier3hike = (float) Math.ceil(((totalbudget * tier3percent)/tier3emp));
        }
        System.out.println("Number of tier3 employees: " + tier3emp);
        System.out.println("Hike for tier3 employees: " + tier3hike);
      }

      // Get the salary increase for the tier2 employees
      // 30% of the total budget is for tier2 employees
      statement  = connection.createStatement();
      resultSet = statement.executeQuery(TIER2_EMP);
      while (resultSet.next()) {
        tier2emp = resultSet.getInt(1);
        if ( tier2emp != 0 ) {
          tier2hike = (float) Math.ceil(((totalbudget * tier2percent)/tier2emp));
        }
        System.out.println("Number of tier2 employees: " + tier2emp);
        System.out.println("Hike for tier2 employees: " + tier2hike);
      }

      // Get the salary increase for the tier1 employees
      // 10% of the total budget is for tier1 employees
      preparedStatement = connection.prepareStatement(TIER1_EMP);
      preparedStatement.setFloat(1,maxsalary);
      resultSet = preparedStatement.executeQuery();
      while (resultSet.next()) {
        tier1emp = resultSet.getInt(1);
        if ( tier1emp != 0 ) {
          tier1hike = (float) Math.ceil(((totalbudget * tier1percent)/tier1emp));
        }
        System.out.println("Number of tier1 employees: " + tier1emp);
        System.out.println("Hike for tier1 employees: " + tier1hike);
      }

      // Give a salary hike to tier3 employees

      preparedStatement = connection.prepareStatement(TIER3_UPDATE);
      preparedStatement.setFloat(1, tier3hike);
      preparedStatement.setFloat(2,minsalary);
      preparedStatement.executeUpdate();

      // Give a salary hike to tier2 employees
      preparedStatement = connection.prepareStatement(TIER2_UPDATE);
      preparedStatement.setFloat(1, tier2hike);
      updateCount = preparedStatement.executeUpdate();

      // Give a salary hike to tier1 employees
      preparedStatement = connection.prepareStatement(TIER1_UPDATE);
      preparedStatement.setFloat(1, tier1hike);
      preparedStatement.setFloat(2,maxsalary);
      preparedStatement.executeUpdate();

      // Verifying if the update was successful.
      // Get the salary of all employees using a ref cursor and print it.
      ((OracleConnection)connection).setCreateStatementAsRefCursor(true);
      Statement stmt = connection.createStatement();
      ((OracleStatement)stmt).setRowPrefetch(1);
      rset = stmt.executeQuery("SELECT Employee_Id, First_Name, Last_Name, Email, Phone_Number, Job_Id, Salary FROM EMPLOYEES");
      // fetch one row
      if (rset.next()) {
        System.out.println("Ename = " + rset.getObject("FIRST_NAME") +
            "-- Salary = " + rset.getObject("salary"));
      }

      // Verifying if the update was successful.
      // Get the total salary of all employees after the salary increase
      resultSet = statement.executeQuery(TOTAL_SALARY);
      while (resultSet.next()) {
        totalsalary = resultSet.getFloat(1);
        System.out.println("Total salary of all employees after the"+
            " salary increase: " + totalsalary);
      }
    } catch (Exception e) {
      e.printStackTrace();
    }
    return rset;
  }
}


