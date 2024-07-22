package com.oracle.jdbc.samples.interceptor.rules;

/**
 * StatementRule implementation that matches fixed string.
 */
public class TokenStatementRule implements StatementRule {
  private String token;

  public TokenStatementRule(String token) {
    if (token == null || token.isEmpty() || token.isBlank()) {
      throw new IllegalArgumentException("must be non-null non-empty non-blank");
    }
    this.token = token;
  }

  @Override
  public boolean matches(String statement) {
    return statement != null && statement.indexOf(this.token) >= 0;
  }

}
