package com.oracle.jdbc.samples.bean;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Level;
import java.util.logging.Logger;
import com.oracle.jdbc.samples.entity.Employee;
import oracle.jdbc.OracleTypes;


import java.sql.PreparedStatement;
import oracle.jdbc.OracleStatement;
import oracle.jdbc.OracleConnection;

import oracle.jdbc.driver.OracleDriver;

/**
 *
 * @author nirmala.sundarappa@oracle.com
 */
public class JdbcBeanImpl implements JdbcBean {

  public static Connection getConnection() throws SQLException {
    DriverManager.registerDriver(new oracle.jdbc.OracleDriver());
    Connection connection = DriverManager.getConnection("jdbc:oracle:thin:@//myorclhost:1521/myorcldbservice", "hr", "hr");
    
    return connection;
  }

  @Override
  public List<Employee> getEmployees() {
    List<Employee> returnValue = new ArrayList<>();
    try (Connection connection = getConnection()) {
      try (Statement statement = connection.createStatement()) {
        try (ResultSet resultSet = statement.executeQuery("SELECT Employee_Id, First_Name, Last_Name, Email, Phone_Number, Job_Id, Salary FROM EMPLOYEES")) {
          while(resultSet.next()) {
            returnValue.add(new Employee(resultSet));
          }
        }
      }
    } catch (SQLException ex) {
      logger.log(Level.SEVERE, null, ex);
      ex.printStackTrace();
    }
    
    return returnValue;
  }

  /**
   * Returns the employee object for the given empId.   Returns
   * @param empId
   * @return
   */
  @Override
  public List<Employee> getEmployee(int empId) {
    List<Employee> returnValue = new ArrayList<>();

    try (Connection connection = getConnection()) {
      try (PreparedStatement preparedStatement = connection.prepareStatement(
          "SELECT Employee_Id, First_Name, Last_Name, Email, Phone_Number, Job_Id, Salary FROM EMPLOYEES WHERE Employee_Id = ?")) {
        preparedStatement.setInt(1, empId);
        try (ResultSet resultSet = preparedStatement.executeQuery()) {
          if(resultSet.next()) {
            returnValue.add(new Employee(resultSet));
          }
        }
      }
    } catch (SQLException ex) {
      logger.log(Level.SEVERE, null, ex);
      ex.printStackTrace();
    }

    return returnValue;
  }

  @Override
  public Employee updateEmployee(int empId) {
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public List<Employee> getEmployeeByFn(String fn) {
    List<Employee> returnValue = new ArrayList<>();

    try (Connection connection = getConnection()) {
      try (PreparedStatement preparedStatement = connection.prepareStatement(
          "SELECT Employee_Id, First_Name, Last_Name, Email, Phone_Number, Job_Id, Salary FROM EMPLOYEES WHERE First_Name LIKE ?")) {
        preparedStatement.setString(1, fn + '%');
        try (ResultSet resultSet = preparedStatement.executeQuery()) {
          while(resultSet.next()) {
            returnValue.add(new Employee(resultSet));
          }
        }
      }
    } catch (SQLException ex) {
      logger.log(Level.SEVERE, null, ex);
      ex.printStackTrace();
    }

    return returnValue;
  }

   @Override
   public List<Employee> incrementSalary (int incrementPct) {
     List<Employee> returnValue = new ArrayList<>();

     try (Connection connection = getConnection()) {
       try (CallableStatement callableStatement = connection.prepareCall("begin ? :=  refcur_pkg.incrementsalary(?); end;")) {
         callableStatement.registerOutParameter(1, OracleTypes.CURSOR);
         callableStatement.setInt(2, incrementPct);
         callableStatement.execute();
         try (ResultSet resultSet = (ResultSet) callableStatement.getObject(1)) {
           while (resultSet.next()) {
             returnValue.add(new Employee(resultSet));
           }
         }
       }
     } catch (SQLException ex) {
       logger.log(Level.SEVERE, null, ex);
       ex.printStackTrace();
     }

     return returnValue;
   }

  static final Logger logger = Logger.getLogger("com.oracle.jdbc.samples.bean.JdbcBeanImpl");
}
