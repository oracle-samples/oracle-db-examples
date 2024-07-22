package com.oracle.jdbc.samples.interceptor;


/**
 * Enumeration of statement rule violation actions.
 */
public enum StatementViolationAction {
  CONSOLE, // log a message to system console.
  LOG, // log a message on com.oracle.jdbc.statement.interceptor logger.
  RAISE // raise an exception and so break the code flow (must be last).
}
