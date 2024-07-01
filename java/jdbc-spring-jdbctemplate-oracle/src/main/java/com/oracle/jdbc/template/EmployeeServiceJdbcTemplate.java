/*
  Copyright (c) 2024, Oracle and/or its affiliates.

  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

package com.oracle.jdbc.template;

import java.util.List;
import java.util.Optional;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.util.Assert;

@Service
@Transactional
public class EmployeeServiceJdbcTemplate implements EmployeeService {

  private final JdbcTemplate jdbcTemplate;
  private static final Logger log = LoggerFactory
      .getLogger(EmployeeServiceJdbcTemplate.class);

  public EmployeeServiceJdbcTemplate(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  RowMapper<Employee> rowMapper = (resultSet, rowNumber) -> new Employee(
      resultSet.getInt(EmployeeSqlStatements.ID.statement()),
      resultSet.getString(EmployeeSqlStatements.NAME.statement()),
      resultSet.getString(EmployeeSqlStatements.ROLE.statement()),
      resultSet.getInt(EmployeeSqlStatements.SALARY.statement()),
      resultSet.getInt(EmployeeSqlStatements.COMMISSION.statement()));

  public List<Employee> findAll() {
    var sqlStatement = EmployeeSqlStatements.FIND_ALL_EMPLOYEES.statement();
    return jdbcTemplate.query(sqlStatement, rowMapper);
  }

  public Optional<Employee> findById(String id) {
    var sqlStatement = EmployeeSqlStatements.FIND_EMPLOYEE_BY_ID.statement();
    Employee employee = null;
    try {
      employee = jdbcTemplate.queryForObject(sqlStatement, rowMapper, id);
    } catch (DataAccessException ex) {
      log.info(EmployeeMessages.EMPLOYEE_NOT_FOUND.getMessage() + id);
    }

    return Optional.ofNullable(employee);
  }

  public void create(Employee employee) {
    String sqlStatement = EmployeeSqlStatements.CREATE_NEW_EMPLOYEE.statement();
    int updated = jdbcTemplate.update(sqlStatement, employee.id(),
        employee.name(), employee.role(), employee.salary(),
        employee.commission());
    log.info(EmployeeMessages.EMPLOYEE_CREATED.getMessage() + employee.name());
    Assert.state(updated == 1L,
        EmployeeMessages.EMPLOYEE_CREATION_FAILED.getMessage()
            + employee.name());
  }

  public void update(Employee employee, String id) {
    String sqlStatement = EmployeeSqlStatements.UPDATE_EMPLOYEE.statement();
    int updated = jdbcTemplate.update(sqlStatement, employee.name(),
        employee.role(), employee.salary(), employee.commission(), id);
    log.info(EmployeeMessages.EMPLOYEE_UPDATED.getMessage() + employee.name());
    Assert.state(updated == 1L,
        EmployeeMessages.EMPLOYEE_UPDATE_FAILED.getMessage() + employee.name());
  }

  public void delete(String id) {
    String sqlStatement = EmployeeSqlStatements.DELETE_EMPLOYEE.statement();
    int updated = jdbcTemplate.update(sqlStatement, id);
    log.info(EmployeeMessages.EMPLOYEE_DELETED.getMessage() + id);
    Assert.state(updated == 1L,
        EmployeeMessages.EMPLOYEE_DELETION_FAILED.getMessage() + id);
  }
}
