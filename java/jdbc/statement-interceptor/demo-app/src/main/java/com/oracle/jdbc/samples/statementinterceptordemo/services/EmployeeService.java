package com.oracle.jdbc.samples.statementinterceptordemo.services;

import com.oracle.jdbc.samples.statementinterceptordemo.models.Employee;

import java.util.List;

/**
 * Service to lookup employee
 */
public interface EmployeeService {
  /**
   * Gets all visible employees
   *
   * @return the list of visible employee. can be empty nt null
   */
  List<Employee> findAll();

  /**
   * Gets a visible employees  by name
   *
   * @return the list of visible employees that match the gven fullname. can be empty nt null
   */
  List<Employee> searchByFullName(final String fullName);

  /**
   * Do what it takes to initialize this service.
   */
  void initialize();
}
