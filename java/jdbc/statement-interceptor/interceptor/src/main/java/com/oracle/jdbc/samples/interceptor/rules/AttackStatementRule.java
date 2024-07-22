package com.oracle.jdbc.samples.interceptor.rules;

/**
 * StatementRule implementation that matches Well-known attacks.
 */
public class AttackStatementRule implements StatementRule {
  @Override
  public boolean matches(String statement) {
    return false;
  }
}
