/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package com.oracle.jdbc.samples.bean;

import java.util.List;
import com.oracle.jdbc.samples.entity.Employee;

/**
 *
 * @author nirmala.sundarappa@oracle.com
 */
public interface JdbcBean {
  /**
   * Get a list of Employees
   * @return List of employees
   */
  public List<Employee> getEmployees();

  /**
   * Get List of employee based on empId.   This will always return one row
   * but returning a List to be make signatures consistent.
   * @param empId
   * @return
   */
  public List<Employee> getEmployee(int empId);

  /**
   * Update employee based on employee-id.   Returns the updated record.
   * @param empId
   * @return updated record.
   */
  public Employee updateEmployee(int empId);

  /**
   * Get List of employees by First Name pattern
   * @param fn
   * @return List of employees with given beginning pattern
   */
  public List<Employee>  getEmployeeByFn(String fn);

  /**
   * Increment salary by a percentage
   * @param incrementPct percent increase
   * @return List of employees with incremented salary
   */
  public List<Employee> incrementSalary(int incrementPct);
}
