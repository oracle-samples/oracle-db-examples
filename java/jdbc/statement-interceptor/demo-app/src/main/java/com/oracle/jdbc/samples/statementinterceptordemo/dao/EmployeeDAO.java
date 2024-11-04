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
