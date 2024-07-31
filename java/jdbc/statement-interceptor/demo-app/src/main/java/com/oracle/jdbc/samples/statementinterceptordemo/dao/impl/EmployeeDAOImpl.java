/*
 * Copyright (c) 2024, Oracle and/or its affiliates.
 *
 *   This software is dual-licensed to you under the Universal Permissive License
 *   (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
 *   2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
 *   either license.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *
 */

package com.oracle.jdbc.samples.statementinterceptordemo.dao.impl;

import com.oracle.jdbc.samples.statementinterceptordemo.dao.EmployeeDAO;
import com.oracle.jdbc.samples.statementinterceptordemo.models.Employee;
import lombok.extern.java.Log;
import org.springframework.context.annotation.Primary;
import org.springframework.jdbc.core.BeanPropertyRowMapper;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.sql.PreparedStatement;
import java.util.List;
import java.util.Random;
import java.util.logging.Level;
import java.util.stream.IntStream;

@Repository
@Primary
@Log
public class EmployeeDAOImpl implements EmployeeDAO {

  private final JdbcTemplate jdbcTemplate;

  private static final int employeeCount = 5;

  public EmployeeDAOImpl(JdbcTemplate jdbcTemplate) {
    this.jdbcTemplate = jdbcTemplate;
  }

  @Override
  public List<Employee> findAll() {
    final var sql = "SELECT * FROM employees WHERE visible = 1";
    return jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(Employee.class));
  }

  @Override
  public List<Employee> findByName(final String fullName) {
    // SQL injection vulnerability
    final var sql =
      "SELECT * FROM employees WHERE visible = 1 AND full_name='" + fullName
      + "'";
    final List<Employee> employees =
      jdbcTemplate.query(sql, new BeanPropertyRowMapper<>(Employee.class));

    return List.copyOf(employees);
  }

  @Override
  public void initializeEmployeesData() {
    try {
      jdbcTemplate.execute("""
                             CREATE TABLE employees (
                               id NUMBER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
                               full_name VARCHAR2(60),
                               visible NUMBER(1) DEFAULT 0
                             )
                             """);
      log.info("Employees table created");
    } catch (Exception e) {
      log.warning("Employees table already exists, no new rows are inserted.");
      return;
    }

    try {
      final var names =
        IntStream.rangeClosed(1, employeeCount).mapToObj(i -> "Employee " + i).toList();

      final var random = new Random();

      jdbcTemplate.batchUpdate(
        "INSERT INTO employees (full_name, visible) VALUES (?, ?) ", names, employeeCount,
        (PreparedStatement ps, String name) -> {
          ps.setString(1, name);
          ps.setShort(2, random.nextBoolean() ? (short) 1 : (short) 0);
        });

      log.info(employeeCount + " Employees are inserted");
    } catch (Exception e) {
      log.log(Level.WARNING, "Employees cannot be inserted", e);
    }
  }

}
