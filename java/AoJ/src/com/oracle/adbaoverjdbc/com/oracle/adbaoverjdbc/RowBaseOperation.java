/*
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package com.oracle.adbaoverjdbc;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.logging.Level;
import jdk.incubator.sql2.SqlException;


/**
 *
 * @param <T>
 */
public abstract class RowBaseOperation<T> extends ParameterizedOperation<T> {
  
  // attributes
  protected final String sqlString;
  protected int fetchSize;
  
  // internal state
  private PreparedStatement jdbcStatement;
  private ResultSetMetaData resultSetMetaData;
  private String[] identifiers;

  protected ResultSet resultSet;
  protected long rowCount;
  protected boolean rowsRemain;
  
  protected static final int NOT_SET = -1;
  
  RowBaseOperation(Session session, OperationGroup operationGroup, String sql) {
    super(session, operationGroup);
    sqlString = sql;
    fetchSize = NOT_SET;
  }
  
  @Override
  CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
    predecessor = attachFutureParameters(predecessor);
    return predecessor
            .thenRunAsync(this::executeQuery, executor)
            .thenCompose(this::moreRows);
  }
  
  abstract CompletionStage<T> moreRows(Object x);  
  
  @Override
  boolean cancel() {
    JdbcCancel();
    super.cancel();
    return rowsRemain; // if all rows processed then
  }
  
  protected void JdbcCancel() {
    try {
        if (jdbcStatement != null) {
          jdbcStatement.cancel();
        }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  

  abstract void executeQuery();
  
  protected void executeJdbcQuery() {
    checkCanceled();
    try {
      jdbcStatement = session.prepareStatement(sqlString);
      initFetchSize();
      setParameters.forEach((String k, ParameterValue v) -> {
        v.set(jdbcStatement, k);
      });
      group.logger.log(Level.FINE, () -> "executeQuery(\"" + sqlString + "\")");
      resultSet = jdbcStatement.executeQuery();
      resultSetMetaData = resultSet.getMetaData();
      rowsRemain = true;
      rowCount = 0;
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  protected void initRowOperationResultSet(PreparedStatement jdbcStatement, ResultSet resultSet) {
    try {
      this.jdbcStatement = jdbcStatement;
      initFetchSize();     
      this.resultSet = resultSet;
      resultSetMetaData = this.resultSet.getMetaData();
      rowsRemain = true;
      rowCount = 0;
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  
  abstract T completeQuery();
  
  protected void completeJdbcQuery() throws SqlException {
    JdbcClose();
    checkCanceled();
  }

  protected void JdbcClose() {
    try {
      // Closing a statement, also close resultset associated with the statement
      jdbcStatement.close();
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }

  String[] getIdentifiers() {
    if (identifiers == null) {
      try {
        if (resultSet == null) {
          throw new IllegalStateException("TODO");
        }
        group.logger.log(Level.FINE, () -> "ResultSet.getMetaData()"); //DEBUG
        int count = resultSetMetaData.getColumnCount();
        identifiers = new String[count];
        for (int i = 0; i < count; i++) {
          identifiers[i] = resultSetMetaData.getColumnLabel(i + 1);
        }
      }
      catch (SQLException ex) {
        throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
      }
    }
    return identifiers;
  }
  
  String enquoteIdentifier(String id) {
    try {
      return jdbcStatement.enquoteIdentifier(id, false);
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  private void initFetchSize() throws SQLException {
    if (fetchSize == NOT_SET) {
      fetchSize = jdbcStatement.getFetchSize();
    }
    else {
      jdbcStatement.setFetchSize(fetchSize);
    }
  }
  
  ResultSet resultSet() {
    return resultSet;
  }
  
  String sqlString() {
    return sqlString;
  }
  
  long rowCount() {
    return rowCount;
  }
  
}
