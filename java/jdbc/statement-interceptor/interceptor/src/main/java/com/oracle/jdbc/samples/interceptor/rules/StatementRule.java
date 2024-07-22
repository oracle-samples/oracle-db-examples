package com.oracle.jdbc.samples.interceptor.rules;

/**
 * Statement Rule definition.
 */
public interface StatementRule {
  /**
   * Checks that a given statement matches this rules.
   *
   * @param statement a statement. cannot be null nor empty
   * @return <code>true</code> if matches, <code>false</code> otherwise
   */
  boolean matches(String statement);
}
