package com.oracle.jdbc.samples.statementinterceptordemo.models;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

/**
 * Employee POJO class
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Employee {
  /**
   * The employee ID
   */
  private String id;
  /**
   * The employee name
   */
  private String fullName;
  /**
   * The employee visiblilty. employee with this set to 0
   * should not be exposed by applications.
   */
  private Short visible;
}
