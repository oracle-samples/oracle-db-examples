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

import jdk.incubator.sql2.ParameterizedRowOperation;
import jdk.incubator.sql2.Result;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.ResultSetMetaData;
import java.sql.SQLException;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.function.Consumer;
import java.util.stream.Collector;

/**
 * Creates separate CompletionStages to execute the query, to fetch and process
 * each block of fetchSize rows and to compute the final result. Yes, these are
 * all synchronous actions so there is no theoretical requirement to do them in 
 * separate CompletionStages. This class does so to break up this large synchronous
 * action into smaller tasks so as to avoid hogging a thread.
 */
class RowOperation<T>  extends ParameterizedOperation<T> 
        implements jdk.incubator.sql2.ParameterizedRowOperation<T> {

  
  private static final int NOT_SET = -1;
  static final Collector DEFAULT_COLLECTOR = Collector.of(
          () -> null,
          (a, v) -> {},
          (a, b) -> null,
          a -> null);
  static <S> RowOperation<S> newRowOperation(Connection conn, OperationGroup grp, String sql) {
    return new RowOperation<>(conn, grp, sql);
  }
  
  // attributes
  private final String sqlString;
  private int fetchSize;
  private Collector collector;
  
  // internal state
  private PreparedStatement jdbcStatement;
  private ResultSet resultSet;
  private Object accumulator;
  private boolean rowsRemain;
  private long rowCount;
  private String[] identifiers;
  
  protected RowOperation(Connection conn, OperationGroup grp, String sql) {
    super(conn, grp);
    fetchSize = NOT_SET;
    collector = DEFAULT_COLLECTOR;
    sqlString = sql;
  }
  
  @Override
  CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
    predecessor = attachFutureParameters(predecessor);
    return predecessor
            .thenRunAsync(this::executeQuery, executor)
            .thenCompose(this::moreRows);
  }
  
  @Override
  boolean cancel() {
    try {
      if (jdbcStatement != null) {
        jdbcStatement.cancel();
      }
      super.cancel();
      return rowsRemain; // if all rows processed then
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }

  /**
   * Return a CompletionStage that fetches the next block of rows. If there are
   * no more rows to fetch return a CompletionStage that completes the query.
   * 
   * @param x ignored
   * @return the next Completion stage in the processing of the query.
   */
  private CompletionStage<T> moreRows(Object x) {
    checkCanceled();
    if (rowsRemain) {
      return CompletableFuture.runAsync(this::handleFetchRows, getExecutor())
              .thenComposeAsync(this::moreRows, getExecutor());
    }
    else {
      return CompletableFuture.supplyAsync(this::completeQuery, getExecutor());
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
  
  private void executeQuery() {
    checkCanceled();
    try {
      jdbcStatement = connection.prepareStatement(sqlString);
      initFetchSize();
      setParameters.forEach((String k, ParameterValue v) -> {
        v.set(jdbcStatement, k);
      });
      System.out.println("executeQuery(\"" + sqlString + "\")");
      resultSet = jdbcStatement.executeQuery();
      accumulator = collector.supplier().get();
      rowsRemain = true;
      rowCount = 0;
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  /**
   * Process fetchSize rows. If the fetches are in sync then all the rows will
   * be in memory after the first is fetched up through the last row processed.
   * The subsequent row, the one after the last row processed should not be in
   * memory and will require a database roundtrip to fetch. This is all assuming
   * the rows are fetched fetchSize rows per roundtrip which may not be the case.
   *
   * @return true if more rows remain
   * @throws SQLException
   */
  private Object handleFetchRows() {
    try {
      for (int i = 0; i < fetchSize && (rowsRemain = resultSet.next()); i++) {
        handleRow();
        rowCount++;
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
    return null;
  }
  
  private void handleRow() throws SQLException {
    checkCanceled();
    try (Row row = new Row(this)) {
      collector.accumulator().accept(accumulator, row);
    }
  }
  
  private T completeQuery() {
    try {
      resultSet.close();
      jdbcStatement.close();
      checkCanceled();
      return (T) collector.finisher().apply(accumulator);
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  private String[] getIdentifiers() {
    if (identifiers == null) {
      try {
        if (resultSet == null) {
          throw new IllegalStateException("TODO");
        }
        System.out.println("ResultSet.getMetaData()"); //DEBUG
        ResultSetMetaData md = resultSet.getMetaData();
        int count = md.getColumnCount();
        identifiers = new String[count];
        for (int i = 0; i < count; i++) {
          identifiers[i] = md.getColumnName(i + 1);
        }
      }
      catch (SQLException ex) {
        throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
      }
    }
    return identifiers;
  }

  @Override
  public ParameterizedRowOperation<T> fetchSize(long rows) throws IllegalArgumentException {
    if (isImmutable() || fetchSize != NOT_SET) throw new IllegalStateException("TODO");
    if (rows < 1) throw new IllegalArgumentException("TODO");
    fetchSize = (int)rows;
    return this;
  }

  @Override
  public <A, S extends T> ParameterizedRowOperation<T> collect(Collector<? super Result.Row, A, S> c) {
    if (isImmutable() || collector != DEFAULT_COLLECTOR) throw new IllegalStateException("TODO");
    if (c == null) throw new IllegalArgumentException("TODO");
    collector = c;
    return this;
  }


  @Override
  public RowOperation<T> onError(Consumer<Throwable> handler) {
    return (RowOperation<T>)super.onError(handler);
  }

  @Override
  public RowOperation<T> timeout(Duration minTime) {
    return (RowOperation<T>)super.timeout(minTime);
  }

  @Override
  public RowOperation<T> set(String id, Object value, SqlType type) {
    return (RowOperation<T>)super.set(id, value, type);
  }

  @Override
  public RowOperation<T> set(String id, CompletionStage<?> source, SqlType type) {
    return (RowOperation<T>)super.set(id, source, type);
  }

  @Override
  public RowOperation<T> set(String id, CompletionStage<?> source) {
    return (RowOperation<T>)super.set(id, source);
  }

  @Override
  public RowOperation<T> set(String id, Object value) {
    return (RowOperation<T>)super.set(id, value);
  }

  static final class Row implements jdk.incubator.sql2.Result.Row, AutoCloseable {
    
    private RowOperation op;
    
    Row(RowOperation op) {
      this.op = op;
    }
    
    @Override
    public void close() {
      op = null;
    }

    @Override
    public long rowNumber() {
      if (op == null) throw new IllegalStateException("TODO");
      return op.rowCount; // keep an independent count because ResultSet.row is limited to int
    }
    
    @Override
    public void cancel() {
      if (op == null) throw new IllegalStateException("TODO");
      throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
    }

    @Override
    public <T> T get(String id, Class<T> type) {
      if (op == null) {
        throw new IllegalStateException("TODO");
      }
      try {
        int index;
        try {
          index = Integer.parseInt(id);
        }
        catch (NumberFormatException ex) {
          return op.resultSet.getObject(id, type);
        }
        return op.resultSet.getObject(index, type);
      }
      catch (SQLException ex) {
        throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), op.sqlString, -1);
      }
    }

    @Override
    public String[] getIdentifiers() {
      if (op == null) throw new IllegalStateException("TODO");
      return op.getIdentifiers();
    }
    
  }
}
