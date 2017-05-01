/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.oracle.jdbc.samples.entity;

import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;

/**
 *
 * @author nirmala.sundarappa@oracle.com
 */
public class Employee {

  private int Employee_Id;
  private String First_Name;
  private String Last_Name;
  private String Email;
  private String Phone_Number;
  private String Job_Id;
  private int Salary;

  public Employee(ResultSet resultSet) throws SQLException {
    this.Employee_Id = resultSet.getInt(1);
    this.First_Name = resultSet.getString(2);
    this.Last_Name = resultSet.getString(3);
    this.Email = resultSet.getString(4);
    this.Phone_Number = resultSet.getString(5);
    this.Job_Id = resultSet.getString(6);
    this.Salary = resultSet.getInt(7);
  }

  public int getEmployee_Id() {
    return Employee_Id;
  }

  public void setEmployee_Id(int Employee_Id) {
    this.Employee_Id = Employee_Id;
  }

  public String getFirst_Name() {
    return First_Name;
  }

  public void setFirst_Name(String First_Name) {
    this.First_Name = First_Name;
  }

  public String getLast_Name() {
    return Last_Name;
  }

  public void setLast_Name(String Last_Name) {
    this.Last_Name = Last_Name;
  }

  public String getEmail() {
    return Email;
  }

  public void setEmail(String Email) {
    this.Email = Email;
  }

  public String getPhone_Number() {
    return Phone_Number;
  }

  public void setPhone_Number(String Phone_Number) {
    this.Phone_Number = Phone_Number;
  }

  public String getJob_Id() {
    return Job_Id;
  }

  public void setJob_Id(String Job_Id) {
    this.Job_Id = Job_Id;
  }

  public int getSalary() {
    return Salary;
  }

  public void setSalary(int Salary) {
    this.Salary = Salary;
  }


}
