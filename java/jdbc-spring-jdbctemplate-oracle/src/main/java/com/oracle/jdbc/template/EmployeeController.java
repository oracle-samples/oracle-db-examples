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

import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class EmployeeController {

  private final EmployeeService employeeService;

  public EmployeeController(EmployeeServiceJdbcTemplate employeeService) {
    this.employeeService = employeeService;
  }

  @GetMapping("/employees")
  List<Employee> findAll() {
    return employeeService.findAll();
  }

  @GetMapping("/employees/{id}")
  Optional<Employee> findById(@PathVariable("id") String id) {
    return employeeService.findById(id);
  }

  @PostMapping("/employees")
  void create(@RequestBody Employee employee) {
    employeeService.create(employee);
  }

  @PutMapping("/employees/{id}")
  void update(@RequestBody Employee employee, @PathVariable("id") String id) {
    employeeService.update(employee, id);
  }

  @DeleteMapping("/employees/{id}")
  void delete(@PathVariable("id") String id) {
    employeeService.delete(id);
  }

}
