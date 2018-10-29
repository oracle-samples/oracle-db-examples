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

import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;
import java.sql.SQLException;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Flow;
import java.util.concurrent.Flow.Subscriber;
import java.util.concurrent.Flow.Subscription;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.Consumer;
import java.util.logging.Level;
import java.util.logging.Logger;
import jdk.incubator.sql2.ParameterizedRowPublisherOperation;
import jdk.incubator.sql2.Result;

/**
 * Creates separate CompletionStages to execute the query, to fetch and process
 * each block of fetchSize rows and to compute the final result. Yes, these are
 * all synchronous actions so there is no theoretical requirement to do them in 
 * separate CompletionStages. This class does so to break up this large synchronous
 * action into smaller tasks so as to avoid hogging a thread.
 */
class RowPublisherOperation<T>  extends RowBaseOperation<T> 
        implements jdk.incubator.sql2.ParameterizedRowPublisherOperation<T> {
  
  
  private static Logger logger = OperationGroup.NULL_LOGGER;


  static final Subscriber<? super Result.RowColumn> DEFAULT_SUBSCRIBER = new Flow.Subscriber<Result.RowColumn>() {
    
          private Subscription subscription;

          @Override    
          public void onComplete() {
            logger.log(Level.FINE, () -> "onComplete");
          }

          @Override
          public void onError(Throwable t) {
            logger.log(Level.FINE, () -> t.getMessage());
          }  

          @Override
          public void onNext(Result.RowColumn row) {  
            // Process a row. We just ignore the row in the default implementation.

            // Request more row
            subscription.request(1);
          }

          @Override
          public void onSubscribe(Subscription subscription) {
            this.subscription = subscription;
            subscription.request(1);
          }            
    };
  
  static <S> RowPublisherOperation<S> newRowPublisherOperation(Session session, OperationGroup grp, String sql) {
    return new RowPublisherOperation<>(session, grp, sql);
  }
  
  // attributes
  private Subscriber<? super Result.RowColumn> subscriber;
  CompletionStage<? extends T> result;
  
  // internal state
  private final AtomicLong demand;
  private int currentBatchFetchCount;
  private CompletableFuture<T> demandStage;
  private boolean cancelSubscription;
  

  protected RowPublisherOperation(Session session, OperationGroup grp, String sql) {
    super(session, grp, sql);
    subscriber = DEFAULT_SUBSCRIBER;
    result = null;
    demand = new AtomicLong(0L);
    currentBatchFetchCount = 0;
    cancelSubscription = false;
    demandStage = new CompletableFuture();
  }
  
  /**
   * Return a CompletionStage that fetches the next block of rows. If there are
   * no more rows to fetch return a CompletionStage that completes the query.
   * 
   * @param x ignored
   * @return the next Completion stage in the processing of the query.
   */
  @Override
  CompletionStage<T> moreRows(Object x) {
    checkCanceled();
    if (rowsRemain) {
      return CompletableFuture.runAsync(this::handleFetchRows, getExecutor())
              .thenComposeAsync(this::demandExist, getExecutor())
              .thenComposeAsync(this::moreRows, getExecutor());
    }
    else {
      return CompletableFuture.supplyAsync(this::completeQuery, getExecutor());
    }
  }

  /**
   * Return a CompletionStage that check for the demand exist or not. If there is
   * a demand then return a CompletionStage that moves to do next stage i.e. moreRows.
   * If there is no demand exist then it stays in incomplete stage and becomes complete
   * when subscribe demands more rows, which trigger next stage i.e. moreRows.
   * 
   * @param x ignored
   * @return the next Completion stage in the processing of the query.
   */
  CompletionStage<T> demandExist(Object x) {
    checkCanceled();
    
    if(demand.get() == 0) {
      request(0);
    }
    
    return demandStage;
  }
  
  // Need synchronization because demandStage can be updated 
  // simulateneously by moreRows() and subscriber.request() calls.
  synchronized void request(long n) {
    checkCanceled();

    // do the right thing if n == 0      
    if(demand.addAndGet(n) > 0) {
      // Mark completion of demand stage.
      demandStage.complete(null);
    }
    else {
      // New demand stage created, which will be complete when demand > 0
      demandStage = new CompletableFuture();
    }
  }
  
  void signalOnError(Throwable th) {
    if(!cancelSubscription) {
      subscriber.onError(th);
      // Termination state, no more signal to subscriber.
      cancelSubscription();
    }
  }

  void signalOnComplete() {
    if(!cancelSubscription) {
      subscriber.onComplete();
      // Termination state, no more signal to subscriber.
      cancelSubscription();
    }
  }
  
  void cancelSubscription() {
    try {
    checkCanceled();
    }
    catch(SqlException sqe) {
      // Log the exception
      logger.log(Level.FINE, () -> sqe.getMessage());
    }
    
    cancelSubscription = true;
    rowsRemain = false;
    demandStage.complete(null);
  }
  
  @Override
  void executeQuery() {
    executeJdbcQuery();
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
      
      checkCanceled();
      
      // Do not fetch more rows, if no demand is pending or subscription get cancel.
      if(!cancelSubscription 
              && demand.get() > 0) {
        if(currentBatchFetchCount == fetchSize)
          currentBatchFetchCount = 0;
        for (; (demand.get() > 0) 
                && (currentBatchFetchCount < fetchSize) 
                && (rowsRemain = resultSet.next()); currentBatchFetchCount++) {
          handleRow();
          rowCount++;
        }
      }
    }
    catch (SQLException ex) {
      signalOnError(ex);
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
    return null;
  }
  
  private void handleRow() throws SQLException {
    checkCanceled();
    try (com.oracle.adbaoverjdbc.Result.RowColumn row = com.oracle.adbaoverjdbc.Result.newRowColumn(this)) {
      subscriber.onNext(row);
      demand.decrementAndGet();
    }
  }
  
  @Override
  T completeQuery() {
    try {
      completeJdbcQuery();
      signalOnComplete();
      return (T) result; 
    }
    catch (SqlException ex) {
      signalOnError(ex);
      throw ex;
    }
  }
  


  @Override
  public ParameterizedRowPublisherOperation<T> subscribe(Flow.Subscriber<? super Result.RowColumn> s,
                                                          CompletionStage<? extends T> result) {
    if (isImmutable() || subscriber != DEFAULT_SUBSCRIBER) 
      throw new IllegalStateException("TODO");
    
    if (s == null) throw new NullPointerException("TODO");
    
    subscriber = s;
    subscriber.onSubscribe(new RowColumnSubscription(this));
    this.result = result;
    
    return this;
  }

  @Override
  public RowPublisherOperation<T> onError(Consumer<Throwable> handler) {
    return (RowPublisherOperation<T>)super.onError(handler);
  }

  @Override
  public RowPublisherOperation<T> timeout(Duration minTime) {
    return (RowPublisherOperation<T>)super.timeout(minTime);
  }

  @Override
  public RowPublisherOperation<T> set(String id, Object value, SqlType type) {
    return (RowPublisherOperation<T>)super.set(id, value, type);
  }

  @Override
  public RowPublisherOperation<T> set(String id, CompletionStage<?> source, SqlType type) {
    return (RowPublisherOperation<T>)super.set(id, source, type);
  }

  @Override
  public RowPublisherOperation<T> set(String id, CompletionStage<?> source) {
    return (RowPublisherOperation<T>)super.set(id, source);
  }

  @Override
  public RowPublisherOperation<T> set(String id, Object value) {
    return (RowPublisherOperation<T>)super.set(id, value);
  }

  private class RowColumnSubscription implements Subscription {
    private final RowPublisherOperation publisher;
    private boolean isCancelled;
    
    
    public RowColumnSubscription(RowPublisherOperation publisher) {
      this.publisher = publisher;
      isCancelled = false;
    }
    
    @Override
    public void request(long n) {
      if (!isCancelled) {
        if (n <= 0) {
          signalOnError(new IllegalArgumentException("non-positive subscription request"));
        }
        else {
          publisher.request(n);
        }
      }
    }
    
    @Override
    public void cancel() {
      if (!isCancelled) {
        isCancelled = true;
        publisher.cancelSubscription();
      }
    }
  }
}
