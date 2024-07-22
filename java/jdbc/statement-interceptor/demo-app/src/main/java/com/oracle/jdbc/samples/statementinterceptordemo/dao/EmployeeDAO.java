package com.oracle.jdbc.samples.statementinterceptordemo.dao;

import com.oracle.jdbc.samples.statementinterceptordemo.models.Employee;

import java.util.List;

/**
 * Employee DAO class
 */
public interface EmployeeDAO {
  /**
   * Finds all amployees
   *
   * @return a list of visible employee
   */
  List<Employee> findAll();

  /**
   * Gets a visible employees  by name
   *
   * @return the list of visible employees that match the gven fullname. can be empty nt null
   */
  List<Employee> findByName(final String name);

  /**
   * Initialize remote DB
   */
  void initializeEmployeesData();
}
