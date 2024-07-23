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

package com.oracle.jdbc.samples.interceptor;

import com.oracle.jdbc.samples.interceptor.rules.StatementRule;

import java.util.Collections;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

/**
 * Interceptor class that filters SQL statement. <br/>
 * When a blacklisted statement is detected, the specified actions in the configuration file are triggered
 * to stop the request before it reach the remote server.
 *
 * @see StatementViolationAction
 */
public class SQLStatementInterceptor implements oracle.jdbc.TraceEventListener {
  private Set<Map.Entry<StatementRule, List<StatementViolationAction>>> rulesSet;

  /**
   * the database operation we're going to scan
   * TODO: find constant definition for this
   */
  private static final String EXECUTE_SQL_OP = "Execute query";

  private static final Logger LOG = Logger.getLogger(SQLStatementInterceptor.class.getPackageName());

  public static final String ACTION_LOGGER_NAME = "com.oracle.jdbc.statement.interceptor";

  private static final Logger actionLogger = Logger.getLogger(ACTION_LOGGER_NAME);

  static {
    // only use handlers that user will attach to us.
    actionLogger.setUseParentHandlers(false);
    actionLogger.setLevel(Level.ALL);
  }

  /**
   * Creates a new interceptor
   *
   * @param rules ordered rules map to be applied on statement, cannot be null.
   */
  public SQLStatementInterceptor(Map<StatementRule, List<StatementViolationAction>> rules) {
    if (rules == null) {
      throw new IllegalArgumentException("cannot be null");
    }
    this.rulesSet = Collections.unmodifiableSet(rules.entrySet());

  }

  /**
   * Intercept SQL statements
   * All defined rules are applied on the statement
   */
  @Override
  public Object roundTrip(Sequence sequence, TraceContext traceContext, Object o) {
    if (sequence.equals(Sequence.BEFORE) &&
      EXECUTE_SQL_OP.equals(traceContext.databaseOperation())) {
      for (Map.Entry<StatementRule, List<StatementViolationAction>> entry : this.rulesSet) {
        if (entry.getKey().matches(traceContext.actualSqlText())) {
          for (StatementViolationAction action : entry.getValue()) {
            switch (action) {
              case LOG:
                actionLogger.severe("violation ! " + traceContext.actualSqlText()); // enough for now
                break;
              case CONSOLE:
                System.err.println("violation ! " + traceContext.actualSqlText()); // enough for now
                break;
              case RAISE:
                throw new SecurityException("SQL violation : " + traceContext.actualSqlText());
            }
          }
        }
      }
    }
    return null;
  }
}
