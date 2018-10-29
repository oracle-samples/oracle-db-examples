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
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;
import jdk.incubator.sql2.Result;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.function.Consumer;
import java.util.stream.Collector;


/**
 * Creates separate CompletionStages to execute the query, to fetch and process
 * each block of fetchSize rows and to compute the final result. Yes, these are
 * all synchronous actions so there is no theoretical requirement to do them in 
 * separate CompletionStages. This class does so to break up this large synchronous
 * action into smaller tasks so as to avoid hogging a thread.
 */
class RowOperation<T>  extends RowBaseOperation<T> 
        implements jdk.incubator.sql2.ParameterizedRowOperation<T> {

  static final Collector DEFAULT_COLLECTOR = Collector.of(
          () -> null,
          (a, v) -> {},
          (a, b) -> null,
          a -> null);
  static <S> RowOperation<S> newRowOperation(Session session, OperationGroup grp, String sql) {
    return new RowOperation<>(session, grp, sql);
  }
  
  // attributes
  private Collector collector;
  
  // internal state
  private Object accumulator;
  
  protected RowOperation(Session session, OperationGroup grp, String sql) {
    super(session, grp, sql);
    collector = DEFAULT_COLLECTOR;
  }
  
  /**
   * Return a CompletionStage that fetches the next block of rows. If there are
   * no more rows to fetch return a CompletionStage that completes the query.
   * 
   * @param x ignored
   * @return the next Completion stage in the processing of the query.
   */
  @Override
  protected CompletionStage<T> moreRows(Object x) {
    checkCanceled();
    if (rowsRemain) {
      return CompletableFuture.runAsync(this::handleFetchRows, getExecutor())
              .thenComposeAsync(this::moreRows, getExecutor());
    }
    else {
      return CompletableFuture.supplyAsync(this::completeQuery, getExecutor());
    }
  }
  
  @Override
  void executeQuery() {
    executeJdbcQuery();
    accumulator = collector.supplier().get();
  }
  
  protected void initRowOperationResultSet(PreparedStatement jdbcStatement, ResultSet resultSet) {
    super.initRowOperationResultSet(jdbcStatement, resultSet);
    accumulator = collector.supplier().get();
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
    try (com.oracle.adbaoverjdbc.Result.RowColumn row = com.oracle.adbaoverjdbc.Result.newRowColumn(this)) {
      collector.accumulator().accept(accumulator, row);
    }
  }
  
  @Override
  T completeQuery() {
    completeJdbcQuery();
    return (T) collector.finisher().apply(accumulator);
  }
  
  public ParameterizedRowOperation<T> fetchSize(long rows) throws IllegalArgumentException {
    if (isImmutable() || fetchSize != NOT_SET) throw new IllegalStateException("TODO");
    if (rows < 1) throw new IllegalArgumentException("TODO");
    fetchSize = (int)rows;
    return this;
  }

  @Override
  public <A, S extends T> ParameterizedRowOperation<T> collect(Collector<? super Result.RowColumn, A, S> c) {
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
}
