package com.oracle.jdbc.samples.statementinterceptordemo.models;

import com.oracle.jdbc.samples.interceptor.StatementViolationAction;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

/**
 * POJO class for interceptor rules
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Rule {
  /**
   * name of the class that implement the rule
   */
  private String className;
  /**
   * parameter used to instance the rule. can be empty
   */
  private String parameter;
  /**
   * list of actions of that rule
   */
  private List<StatementViolationAction> actions;
}
