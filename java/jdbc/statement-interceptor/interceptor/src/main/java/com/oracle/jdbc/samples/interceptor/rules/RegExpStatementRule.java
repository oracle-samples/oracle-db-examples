package com.oracle.jdbc.samples.interceptor.rules;

import java.util.regex.Pattern;

/**
 * StatementRule implementation that matches regular expression.
 */
public class RegExpStatementRule implements StatementRule {
  private final Pattern pattern;

  public RegExpStatementRule(String regExp) {
    pattern = Pattern.compile(regExp);
  }

  @Override
  public boolean matches(String statement) {
    return this.pattern.matcher(statement).matches();
  }
}
