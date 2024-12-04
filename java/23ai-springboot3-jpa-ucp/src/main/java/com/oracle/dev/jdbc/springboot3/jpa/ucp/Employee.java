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

package com.oracle.dev.jdbc.springboot3.jpa.ucp;

import java.util.Objects;

import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.Id;
import jakarta.persistence.Table;

@Entity
@Table(name = "EMPLOYEE", schema = "SYSTEM")
public class Employee {

  private @Id @GeneratedValue Long id;
  private String name;
  private String job;
  private Integer salary;
  private Integer commission;

  public Employee() {
  }

  public Employee(Long id, String name, String job, Integer salary,
      Integer commission) {
    this.id = id;
    this.name = name;
    this.job = job;
    this.salary = salary;
    this.commission = commission;
  }

  public Long getId() {
    return id;
  }

  public void setId(Long id) {
    this.id = id;
  }

  public String getName() {
    return name;
  }

  public void setName(String name) {
    this.name = name;
  }

  public String getJob() {
    return job;
  }

  public void setJob(String job) {
    this.job = job;
  }

  public Integer getSalary() {
    return salary;
  }

  public void setSalary(Integer salary) {
    this.salary = salary;
  }

  public Integer getCommission() {
    return commission;
  }

  public void setCommission(Integer commission) {
    this.commission = commission;
  }

  @Override
  public int hashCode() {
    return Objects.hash(commission, id, job, name, salary);
  }

  @Override
  public boolean equals(Object obj) {
    if (this == obj)
      return true;
    if (obj == null)
      return false;
    if (getClass() != obj.getClass())
      return false;
    Employee other = (Employee) obj;
    return Objects.equals(commission, other.commission)
        && Objects.equals(id, other.id) && Objects.equals(job, other.job)
        && Objects.equals(name, other.name)
        && Objects.equals(salary, other.salary);
  }

  public String toString() {
    return String.format("%20s %20s %20s %20s %20s", id, name, job, salary,
        commission);

  }
}
