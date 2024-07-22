package com.oracle.jdbc.samples.statementinterceptordemo.services.impl;

import com.oracle.jdbc.samples.statementinterceptordemo.dao.EmployeeDAO;
import com.oracle.jdbc.samples.statementinterceptordemo.models.Employee;
import com.oracle.jdbc.samples.statementinterceptordemo.services.EmployeeService;
import lombok.AllArgsConstructor;
import org.springframework.context.annotation.Primary;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Objects;

/**
 * Special service instance that do not use the interceptor
 */
@Service
@Primary
@AllArgsConstructor
public class EmployeeServiceImpl implements EmployeeService {

  private final EmployeeDAO dao;

  @Override
  public List<Employee> findAll() {
    return dao.findAll();
  }

  @Override
  public List<Employee> searchByFullName(final String fullName) {
    Objects.requireNonNull(fullName, "Full name cannot be null");
    return dao.findByName(fullName);
  }

  @Override
  public void initialize() {
    dao.initializeEmployeesData();
  }

}
