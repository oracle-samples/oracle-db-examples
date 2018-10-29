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

import java.lang.reflect.Array;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.time.Duration;
import java.util.List;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.function.Consumer;
import java.util.logging.Level;
import java.util.stream.Collector;
import jdk.incubator.sql2.ArrayRowCountOperation;
import jdk.incubator.sql2.Result;

/**
 *
 * @param <T>
 */
class ArrayCountOperation<T> extends ParameterizedOperation<T>
        implements ArrayRowCountOperation<T> {
  
  private static final Collector DEFAULT_COLLECTOR = Collector.of(
          () -> null,
          (a, v) -> {},
          (a, b) -> null,
          a -> null);
  
  
  /**
   * Factory method to create ArrayCountOperations.
   * 
   * @param <S> the type of the value of the ArrayCountOperation
   * @param session the Session the ArrayCountOperation belongs to
   * @param grp the GroupOperation the ArrayCountOperation is a member of
   * @param sql the SQL string to execute. Must return a count.
   * @return a new ArrayCountOperation that will execute sql.
   */
  static <S> ArrayCountOperation<S> newArrayCountOperation(Session session, OperationGroup grp, String sql) {
    return new ArrayCountOperation<>(session, grp, sql);
  }
  
  // attributes
  private final String sqlString;
  private  Collector<? super Result.RowCount, Object , ? extends T> countCollector;
  
  PreparedStatement jdbcStatement;

  ArrayCountOperation(Session session, OperationGroup operationGroup, String sql) {
    super(session, operationGroup);
    countCollector = DEFAULT_COLLECTOR;
    sqlString = sql;
  }

  @Override
  public <A, S extends T> ArrayRowCountOperation<T> collect(Collector<? super Result.RowCount, A, S> c) {
    if (isImmutable() || countCollector != DEFAULT_COLLECTOR) throw new IllegalStateException("TODO");
    if (c == null) throw new IllegalArgumentException("TODO");
    countCollector = (Collector<? super Result.RowCount, Object , ? extends T>) c;
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

      // Get parameter ids
      String[] keys = (String[])setParameters.keySet().toArray(new String[setParameters.size()]);
      
      // Get parameter values
      ParameterValue[] paramVals =  (ParameterValue[]) setParameters.values().toArray(new ParameterValue[setParameters.size()]);
      
      int paramIndex;
      int batchSize;
      
      // Get the batch size from first parameter list/array size
      // TODO: Need to check all parameter value list or value array of same size
      Object paramVal = paramVals[0].value;
      if(paramVal instanceof List)
        batchSize = ((List)paramVal).size();
      else
        batchSize = Array.getLength(paramVal);

      // Loop for each value in the list or an array
      for(int i = 0; i < batchSize; i++) {
        // Loop for each parameter to add a batch
        for(paramIndex = 0; paramIndex < keys.length; paramIndex++) {
          ParameterValue v = paramVals[paramIndex];
          Object val = getParamVal(v, i);
          v = new ParameterValue(val, v.type);
          v.set(jdbcStatement, keys[paramIndex]);
        }
        
        // Add batch
        jdbcStatement.addBatch();
      }
      
      // Execute batch
      group.logger.log(Level.FINE, () -> "executeLargeBatch(\"" + sqlString + "\")");
      long[] counts = jdbcStatement.executeLargeBatch();
      
      // Get final count using the collector
      Object container = countCollector.supplier().get();
      for (long c : counts)
         countCollector.accumulator().accept(container, com.oracle.adbaoverjdbc.Result.newRowCount(c));
     return countCollector.finisher().apply(container);
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }

  // Get parameter value from list or an array
  private Object getParamVal(ParameterValue paramVal, int index) {
    if(paramVal.value instanceof List)
      return ((List)(paramVal.value)).get(index);
    else
      return Array.get(paramVal.value, index);
  }
  
  // Covariant overrides
  
  @Override
  public ArrayCountOperation<T> set(String id, List<?> values) {
    return (ArrayCountOperation<T>)super.set(id, values);
  }

  @Override
  public ArrayCountOperation<T> set(String id, List<?> values, SqlType type) {
    return (ArrayCountOperation<T>)super.set(id, values, type);
  }

  @Override
  public <S> ArrayRowCountOperation<T> set(String id, S[] values, SqlType type) {
    return (ArrayCountOperation<T>)super.set(id, values, type);
  }
  
  @Override
  public <S> ArrayRowCountOperation<T> set(String id, S[] values) {
    return (ArrayCountOperation<T>)super.set(id, values);
  }
  
  
  @Override
  public ArrayCountOperation<T> set(String id, CompletionStage<?> source) {
    return (ArrayCountOperation<T>)super.set(id, source);
  }

  @Override
  public ArrayCountOperation<T> set(String id, CompletionStage<?> source, SqlType type) {
    return (ArrayCountOperation<T>)super.set(id, source, type);
  }

  @Override
  public ArrayCountOperation<T> timeout(Duration minTime) {
    return (ArrayCountOperation<T>)super.timeout(minTime);
  }

  @Override
  public ArrayCountOperation<T> onError(Consumer<Throwable> handler) {
    return (ArrayCountOperation<T>)super.onError(handler);
  }

}
