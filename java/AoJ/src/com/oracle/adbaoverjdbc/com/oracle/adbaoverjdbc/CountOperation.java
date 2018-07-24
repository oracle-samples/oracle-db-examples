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

import jdk.incubator.sql2.RowOperation;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.Duration;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.logging.Level;
import jdk.incubator.sql2.ParameterizedRowCountOperation;
import jdk.incubator.sql2.Result;

/**
 *
 * @param <T>
 */
class CountOperation<T> extends ParameterizedOperation<T>
        implements ParameterizedRowCountOperation<T> {
  
  static private final Function DEFAULT_PROCESSOR = c -> null;
  
  /**
   * Factory method to create CountOperations.
   * 
   * @param <S> the type of the value of the CountOperation
   * @param session the Session the CountOperation belongs to
   * @param grp the GroupOperation the CountOperation is a member of
   * @param sql the SQL string to execute. Must return a count.
   * @return a new CountOperation that will execute sql.
   */
  static <S> CountOperation<S> newCountOperation(Session session, OperationGroup grp, String sql) {
    return new CountOperation<>(session, grp, sql);
  }
  
  // attributes
  private final String sqlString;
  private Function<? super Result.RowCount, ? extends T> countProcessor;
  
  PreparedStatement jdbcStatement;

  CountOperation(Session session, OperationGroup operationGroup, String sql) {
    super(session, operationGroup);
    countProcessor = DEFAULT_PROCESSOR;
    sqlString = sql;
  }

  @Override
  public RowOperation<T> returning(String... keys) {
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public CountOperation<T> apply(Function<Result.RowCount, ? extends T> processor) {
    if (isImmutable() || countProcessor != DEFAULT_PROCESSOR) throw new IllegalStateException("TODO");
    if (processor == null) throw new IllegalArgumentException("TODO");
    countProcessor = processor;
    return this;
  }

  @Override
  CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
    predecessor = attachFutureParameters(predecessor);
    return predecessor
            .thenApplyAsync(this::executeQuery, executor);
  }

  /**
   * Execute the SQL query, process the returned count, and return the result of 
   * processing the returned count.
   * 
   * @param ignore not used
   * @return the result of processing the count
   */
  private T executeQuery(Object ignore) {
    checkCanceled();
    try {
      jdbcStatement = session.prepareStatement(sqlString);
      setParameters.forEach((String k, ParameterValue v) -> {
        v.set(jdbcStatement, k);
      });
      group.logger.log(Level.FINE, () -> "executeUpdate(\"" + sqlString + "\")");
      long c = jdbcStatement.executeLargeUpdate();
      return countProcessor.apply(new RowCount(c));
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  // Covariant overrides
  
  @Override
  public CountOperation<T> set(String id, Object value) {
    return (CountOperation<T>)super.set(id, value);
  }

  @Override
  public CountOperation<T> set(String id, Object value, SqlType type) {
    return (CountOperation<T>)super.set(id, value, type);
  }

  @Override
  public CountOperation<T> set(String id, CompletionStage<?> source) {
    return (CountOperation<T>)super.set(id, source);
  }

  @Override
  public CountOperation<T> set(String id, CompletionStage<?> source, SqlType type) {
    return (CountOperation<T>)super.set(id, source, type);
  }

  @Override
  public CountOperation<T> timeout(Duration minTime) {
    return (CountOperation<T>)super.timeout(minTime);
  }

  @Override
  public CountOperation<T> onError(Consumer<Throwable> handler) {
    return (CountOperation<T>)super.onError(handler);
  }

  /**
   * Represents the result of a SQL execution that is an update count. 
   * 
   * ISSUE: It's not obvious this type is more valuable than just using
   * java.lang.Long. Result.Count exists to clearly express that the input arg 
   * to the processor Function is a count. Could rely on documentation but this
   * seems like it might be important enough to capture in the type system. There
   * also may be non-numeric return values that Result.Count could express, eg
   * success but number unknown.
   */
  static class RowCount implements Result.RowCount {

    private long count = -1;
    
    private RowCount(long c) {
      count = c;
    }
    
    @Override
    public long getCount() {
      return count;
    }
    
  }
}
