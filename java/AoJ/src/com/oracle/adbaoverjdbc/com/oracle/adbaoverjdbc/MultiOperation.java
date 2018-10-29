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

import java.sql.CallableStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.Executor;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.logging.Level;

import jdk.incubator.sql2.Operation;
import jdk.incubator.sql2.Result.OutColumn;
import jdk.incubator.sql2.RowCountOperation;
import jdk.incubator.sql2.RowOperation;
import jdk.incubator.sql2.RowPublisherOperation;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlSkippedException;
import jdk.incubator.sql2.SqlType;
import jdk.incubator.sql2.Submission;

/**
 * A multi-operation is an {@link Operation} that returns one or more results in
 * addition to the out result defined by the {@link Operation}. Each result is
 * processed by an {@link Operation}. The {@link Operation}s can be created by
 * calling
 * {@link MultiOperation#rowOperation}, {@link MultiOperation#rowProcessorOperation},
 * or {@link MultiOperation#rowCountOperation} if the kind of results is known.
 * These results are processed in the order the {@link Operation}s are
 * submitted. Any results not processed by an explicit {@link Operation} is
 * processed by calling the appropriate handler specified by
 * {@link MultiOperation#onRows} or {@link MultiOperation#onCount}. If any
 * result is an error that error is processed by calling the handler specified
 * by {@link Operation#onError} of the corresponding {@link Operation}. If the
 * appropriate handler is not specified that result is ignored, including
 * errors.
 *
 *
 * @param <T> The type of the result of this {@link Operation}
 */
class MultiOperation<T> extends OutOperation<T>
                               implements jdk.incubator.sql2.MultiOperation<T> {

  private static final int NOT_SET = -1;
  
  static private final BiConsumer DEFAULT_COUNT_HANDLER = (t,u) -> {};
  static private final BiConsumer DEFAULT_ROWS_HANDLER  = (t,u) -> {};
  static private final BiConsumer DEFAULT_ERROR_HANDLER = null;
  
  // attributes
  private final String sqlString;
  private int fetchSize;
  
  // internal state
  
  /** CallableStatement to execute the given SQL */
  private CallableStatement jdbcStatement;
  
  /** Number of the resultset. 1, 2, 3 etc. */
  private int resultNum = 0;
  
  /** Count result handler. Process row count, if no child count operation has been submitted to handle it. */
  private BiConsumer<Integer, RowCountOperation<T>> countHandler;
  
  /** Rows result handler. Process rows, if no child row operation has been submitted to handle it. */
  private BiConsumer<Integer, RowOperation<T>> rowsHandler;
  
  private BiConsumer<Integer, Throwable> errorHandler;
  
  /** Keep track of child operation result stage */
  private CompletionStage<?> resultStage = CompletableFuture.completedFuture(null);

  /** List of submitted child operations. These operation created from MultiOperation.
      Add in the list when it got submitted. 
   */
  private ConcurrentLinkedQueue<Operation> resultOperations;
  
  
  // Factory method
  static <S> MultiOperation<S> newMultiOperation(Session session, OperationGroup grp, String sql) {
    return new MultiOperation<>(session, grp, sql);
  }
  
  protected MultiOperation(Session session, OperationGroup grp, String sql) {
    super(session, grp,null);
    fetchSize = NOT_SET;
    countHandler = DEFAULT_COUNT_HANDLER;
    rowsHandler = DEFAULT_ROWS_HANDLER;
    errorHandler = DEFAULT_ERROR_HANDLER;
    
    sqlString = sql;
    resultOperations = new ConcurrentLinkedQueue<Operation>();
  }
  
 /**
  * Once the predecessor gets completed (i.e. session gets created successfully),
  * then next stage will be to execute the query. After that stage completed successfuly,
  * it goes into moreResults stage, where it iterate through each resultset one after the another,
  *  until exhausted with all resultset associated with this query execution.
  * 
  * @param tail the predecessor of this operation. Completion of tail starts
  * execution of this Operation
  * @param executor used for asynchronous execution
  * @return completion of this CompletableFuture means this Operation is
  * complete. The value of the Operation is the value of the CompletableFuture.
  */ 
  @Override
  CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
    predecessor = attachFutureParameters(predecessor);
    return predecessor
            .thenApplyAsync(this::executeQuery, executor)
            .thenComposeAsync(this::moreResults, executor);
  }
  
  /**
   * Execute query using a JDBC driver.
   * 
   * @param x
   * @return true when it returns resultset otherwise false.
   */
  private Boolean executeQuery(Object x) {
    boolean queryResult;
    
    checkCanceled();
    try {
      jdbcStatement = session.prepareCall(sqlString);
      initFetchSize();
      registerOutParameters(jdbcStatement);
      setParameters.forEach((String k, ParameterValue v) -> {
        v.set(jdbcStatement, k);
      });
      group.logger.log(Level.FINE, () -> "executeQuery(\"" + sqlString + "\")");
      queryResult = jdbcStatement.execute();
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }

    return  queryResult;
  }

  /**
   * Set the fetch size.
   * 
   * @throws SQLException
   */
  private void initFetchSize() throws SQLException {
    if (fetchSize == NOT_SET) {
      fetchSize = jdbcStatement.getFetchSize();
    }
    else {
      jdbcStatement.setFetchSize(fetchSize);
    }
  }
  
  /**
   * Trigger the child operation when next resultset or row count is available.
   * If there are no more resultset then  (i.e. getMoreResult() returns false
   * and getLargeUpdateCount() returns -1) move to complete query stage.
   * 
   * @param isRows true when it has resultset otherwise false.
   * @return the next Completion stage in the processing of resultsets of the query.
   */
  private CompletionStage<T> moreResults(Boolean isRows) {
    
    try {
      checkCanceled();
      ++resultNum;
      
      // Is it a resultset?
      if (isRows) 
        return processChildRowOperation();
      else {
        // Process update count
        long updateCount = jdbcStatement.getLargeUpdateCount();
        
        // Is it a row count?
        if (updateCount != -1) 
          return processChildRowCountOperation(updateCount);
        else {
          // isRows is false and updateCount == -1, so no more results
          return processEndOfResults();
        }
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  /**
   * Process next resultset. Get the child operation from the queue (if any submitted) and pass
   * the resultset to it for the processing. If no child operation in the queue then process resultset
   * with the help of user supplied row handler or the default one. Wait for the child operation or
   * the handler to process all rows of a resultset.
   * 
   * @return the completion stage of the child operation.
   * @throws SQLException
   */
  private CompletionStage<T> processChildRowOperation() throws SQLException {
    // Get the result set
    ResultSet resultSet = jdbcStatement.getResultSet();

    // Remove child operation, if any exist
    Operation operationFromQueue = resultOperations.poll();
    // Keep as effective final, because it uses in lambda expression
    Operation operation;
    
    boolean onRowsHandler = (operationFromQueue == null);
    
    if (onRowsHandler) {
      // Handle using onRows handler.
      operation = new MultiRowOperation<T>(session, group, true);
    }
    else
      operation = operationFromQueue;
    
    if (!(operation instanceof  ChildRowOperation)) {
      // Current result is a resultset and result operation queue type is not as expected,
      // which can process the resultset.
      // Throw invalid state
      throw new IllegalStateException("TODO");
    }
    
    // Trigger child operation to process the resultset
    resultStage = ((ChildRowOperation)operation).setResultSet(resultSet, resultStage);
    
    if (onRowsHandler)
      resultStage = resultStage.thenRun( () -> rowsHandler.accept(resultNum, (RowOperation<T>)operation) );
    
    
    // Wait in resultProcesses stage until child operation process the result.
    // Then again move to moreResult stage to process next resultset.
    return resultStage
             .thenComposeAsync(((ChildRowOperation)operation)::resultProcessed, getExecutor())
             .thenComposeAsync(this::checkForMoreResults, getExecutor());
  }
  
  
  /**
   * Check next resultset exist or not. Send the true/false to moreResults
   * and it will either process next resultstage or call completeQuery to finish
   * resultset processing.
   *  
   * @param x Ignored
   * @return the next Completion stage in the processing of resultsets of the query.
   */
  private CompletionStage<T> checkForMoreResults(Object x)  {
    return ((CompletableFuture)resultStage)
        .supplyAsync(() -> {
          try {
            return jdbcStatement.getMoreResults();
          } catch (SQLException ex) {
            throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
          }
        })
        .thenComposeAsync(this::moreResults, getExecutor());
  }
  
  /**
   * 
   * Process next update count. Get the child operation from the queue (if any submitted) and pass
   * the update count to it for the processing. If no child operation in the queue then process update count 
   * with the help of user supplied rowcount handler or the default one. Wait for the child operation or
   * the handler to process the update count.
   * 
   * @param updateCount
   * @return the completion stage of the child operation.
   */
  private CompletionStage<T> processChildRowCountOperation(long  updateCount) {

    // Remove child operation, if any exist
    Operation operationFromQueue = resultOperations.poll();
    // Keep as effective final, because it uses in lambda expression
    Operation operation;
    
    boolean onCountHandler = (operationFromQueue == null); 
    
    if (onCountHandler) {
      // Handle using onCount handler
      operation = new MultiRowCountOperation<T>(session, group, true);
    }
    else
      operation = operationFromQueue;
      
    if (!(operation instanceof  ChildRowCountOperation)) {
      // Current result is a row count and result operation queue type is not as expected,
      // which can process the row count.
      // Throw invalid state
      throw new IllegalStateException("TODO");
    }
      
    resultStage = ((ChildRowCountOperation)operation).setRowCount(updateCount, resultStage);
    
    if (onCountHandler)
      resultStage = resultStage.thenRun( () -> countHandler.accept(resultNum, (RowCountOperation<T>)operation));
    
      
    return resultStage
            .thenComposeAsync(((ChildRowCountOperation)operation)::resultCountProcessed, getExecutor())
            .thenComposeAsync(this::checkForMoreResults, getExecutor());
  }
  
  /**
   * All resultsets or update counts has been processed. Now move to query completion stage.
   * 
   * @return final completion stage.
   * @throws SQLException
   * 
   */
  private CompletionStage<T> processEndOfResults() throws SQLException {
    // All results are processed.
    // Move to complete query stage
    resultNum--;
    return CompletableFuture.supplyAsync(this::completeQuery, getExecutor());
  }
  
  
  /**
   * This method gets call after all resultset has been processed.
   * If output parameter processor exist, then call it using apply 
   * and let it process the out parameter value(s).
   * 
   * 
   * @return final computation.
   */
  private T completeQuery() {
    try {
      checkCanceled();
      
      // If there is no output parameter processor then
      // close the statement.
      if(processor == null)
          jdbcStatement.close();
      
      return  (T)((processor != null) 
                  ? processor.apply(com.oracle.adbaoverjdbc.Result.newOutColumn(this))
                  : null);
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
    }
  }
  
  @Override
  protected SqlSkippedException handleError(Throwable ex) {
    if (errorHandler != null) 
      errorHandler.accept(resultNum, ex);
    return super.handleError(ex);
  }
  
  @Override
  public MultiOperation<T> onError(Consumer<Throwable> handler) {
    if (this.errorHandler != null) 
      throw new IllegalStateException("TODO");
      
    return (MultiOperation<T>)super.onError(handler);
  }

  @Override
  public MultiOperation<T> timeout(Duration minTime) {
    return (MultiOperation<T>)super.timeout(minTime);
  }

  @Override
  public MultiOperation<T> set(String id, Object value, SqlType type) {
    return (MultiOperation<T>)super.set(id, value, type);
  }

  @Override
  public MultiOperation<T> set(String id, CompletionStage<?> source, SqlType type) {
    return (MultiOperation<T>)super.set(id, source, type);
  }

  @Override
  public MultiOperation<T> set(String id, CompletionStage<?> source) {
    return (MultiOperation<T>)super.set(id, source);
  }

  @Override
  public MultiOperation<T> set(String id, Object value) {
    return (MultiOperation<T>)super.set(id, value);
  }

  @Override
  public MultiOperation<T> apply(Function<OutColumn, ? extends T> processor) {
    super.apply(processor);
    return this;
  }

  @Override
  public jdk.incubator.sql2.MultiOperation<T> onCount(
      BiConsumer<Integer, RowCountOperation<T>> handler) {
    if (isImmutable() || countHandler != DEFAULT_COUNT_HANDLER) throw new IllegalStateException("TODO");
    if (handler == null) throw new IllegalArgumentException("TODO");
    
    countHandler = handler;
    
    return this;
  }

  @Override
  public jdk.incubator.sql2.MultiOperation<T> onError(BiConsumer<Integer, Throwable> handler) {
    if (isImmutable() || errorHandler != DEFAULT_ERROR_HANDLER) throw new IllegalStateException("TODO");
    if (handler == null) throw new IllegalArgumentException("TODO");
    if (super.errorHandler != null) throw new IllegalStateException("TODO");
    
    errorHandler = handler;
    
    return this;
  }

  @Override
  public jdk.incubator.sql2.MultiOperation<T> onRows(
      BiConsumer<Integer, RowOperation<T>> handler) {
    if (isImmutable() || rowsHandler != DEFAULT_ROWS_HANDLER) throw new IllegalStateException("TODO");
    if (handler == null) throw new IllegalArgumentException("TODO");
    
    rowsHandler = handler;
    
    return this;
  }

  @Override
  public MultiOperation<T> outParameter(String id, SqlType type) {
    super.outParameter(id, type);
    return this;
  }

  @Override
  public RowCountOperation<T> rowCountOperation() {
    return new MultiRowCountOperation<T>(session, group, false);
  }

  @Override
  public RowOperation<T> rowOperation() {
    return new MultiRowOperation<T>(session, group, false);
  }

  @Override
  public RowPublisherOperation<T> rowPublisherOperation() {
    return new MultiRowPublisherOperation<T>(session, group);
  }
  
  interface ChildRowCountOperation<T> {
    /**
     * Trigger from the parent MultiOperation to process the current row count.
     * 
     * @param rowCount
     * @param resultStage
     * @return
     */
    CompletionStage<T>  setRowCount(long rowCount, CompletionStage<T> resultStage);  
    
    /**
     * Wait for child operation complete the current result count.
     * 
     * @param x Ignored
     * @return completion stage of the child operation.
     */
    CompletionStage<T> resultCountProcessed(Object x);
  }

  interface ChildRowOperation<T> {
    /**
     * Trigger from the parent MultiOperation to process the current resultset.
     * 
     * @param resultSet
     * @param resultStage
     * @return
     */
    CompletionStage<T>  setResultSet(ResultSet resultSet, CompletionStage<T> resultStage);
    
    /**
     * Wait for child operation complete the current result.
     * 
     * @param x Ignored
     * @return completion stage of the child operation.
     */
    CompletionStage<T> resultProcessed(Object x);
  }
  
  /**
   *  Child row count operation class.
   *  It waits for operation to submit, then add in the operation queue.
   *  Then it waits for parent MultiOperation gives the row count.
   *  Once it receives the row count, process it using a count processor.
   *  Then complete the current resultset stage, so parent operation continue
   *  to next stage. It also returns child operation completion stage to the application.
   *
   * @param <T>
   */
  class MultiRowCountOperation<T> extends CountOperation<T> 
                                  implements ChildRowCountOperation<T> {
    private CompletableFuture<T> resultCF;
    private long rowCount;
    private boolean countHandler;
    private CompletionStage<T> opCompletetionStage;
    
    
    MultiRowCountOperation(Session session, OperationGroup operationGroup, boolean countHandler) {
      super(session, operationGroup, null);
      resultCF = new CompletableFuture<T>();
      rowCount = -1;
      this.countHandler = countHandler;
      opCompletetionStage = new CompletableFuture<T>();
    }
    
    @Override
    public Submission<T> submit() {
      Submission<T>  submission = super.submit();
      return new MultiOperationChildSubmission(submission, opCompletetionStage);
    }
    
    @Override
    CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
      addInResultQueue(null);
      
      predecessor
              .thenComposeAsync(this::resultExist, executor);
      
      return (CompletionStage<T>)predecessor;
    }

    /**
     * Add the child operation in the parent operation queue.
     * Count handlers are directly process without putting in the queue.
     * 
     * @param x
     * @return
     */
    private CompletionStage<T> addInResultQueue(Object x) {
      checkCanceled();
      if(!countHandler)
        resultOperations.add(this);
      else
        processRowCount(null);
      
      return null;    
    }

    /**
     * Wait for parent MultiOperation trigger with row count.
     * 
     * @param x
     * @return
     */
    private CompletionStage<T> resultExist(Object x) {
      checkCanceled();
      return resultCF;    
    }
    
    /**
     * Process the row count.
     * Complete the current result stage, so parent MultiOperation continue
     * to his next stage.
     * Set the completion stage of this child operation.
     * 
     * @param ignore
     * @return
     */
    private T processRowCount(Object ignore) {
      checkCanceled();
      T rc =  countProcessor.apply(new RowCount(rowCount));
      
      // Trigger to move on next result
      ((CompletableFuture)opCompletetionStage).complete(rc);
      
      return rc;
    }
    
    /**
     * Trigger from the parent MultiOperation to process the current row count.
     * 
     * @param rowCount
     * @param resultStage
     * @return
     */
    @Override
    public CompletionStage<T>  setRowCount(long rowCount, CompletionStage<T> resultStage) {
      checkCanceled();
      this.rowCount = rowCount;
      resultCF.complete(null);
      if(!countHandler)
        return resultStage
                .thenApply(this::processRowCount);
      else
        return resultStage;
    }
    
    /**
     * Wait for child operation complete the current result count.
     * 
     * @param x Ignored
     * @return completion stage of the child operation.
     */
    public CompletionStage<T> resultCountProcessed(Object x) {
      checkCanceled();
      return opCompletetionStage;    
    }
    
  } // MultiRowCountOperation
  
  /**
   *  Child row operation class.
   *  It waits for operation to submit, then add in the operation queue.
   *  Then it waits for parent MultiOperation gives the resultset.
   *  Once it receives the resultset, process it using a row operation.
   *  Then complete the current resultset stage, so parent operation continue
   *  to next stage. It also returns child operation completion stage to the application.
   *
   * @param <T>
   */
   class MultiRowOperation<T> extends com.oracle.adbaoverjdbc.RowOperation<T>
                              implements ChildRowOperation<T> {
    private CompletableFuture<T> resultCF;
    private long rowCount;
    private boolean rowsHandler;
    private CompletionStage<T> opCompletetionStage;
    private ResultSet rowsHandlerResultSet;    
    
    MultiRowOperation(Session session, OperationGroup operationGroup, boolean rowsHandler) {
      super(session, operationGroup, null);
      resultCF = new CompletableFuture<T>();
      rowCount = -1;
      this.rowsHandler = rowsHandler;
      opCompletetionStage = new CompletableFuture<T>();
      rowsHandlerResultSet = null;
    }
    
    @Override
    public Submission<T> submit() {
      Submission<T>  submission = super.submit();
      return new MultiOperationChildSubmission(submission, opCompletetionStage);
    }
    
    @Override
    CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
      addInResultQueue(null);
      predecessor
              .thenComposeAsync(this::resultExist, executor);
      
      return (CompletionStage<T>)predecessor;
    }

    /**
     * Add the child operation in the parent operation queue.
     * Row handlers are directly process without putting in the queue.
     * 
     * @param x
     * @return
     */
    private CompletionStage<T> addInResultQueue(Object x) {
      checkCanceled();
      
      if(!rowsHandler)
        resultOperations.add(this);
      else
        setRowHandlerResultSet();
      
      return null;    
    }

    /**
     * Wait for parent MultiOperation trigger with resultset.
     * 
     * @param x
     * @return
     */
    private CompletionStage<T> resultExist(Object x) {
      checkCanceled();
      return resultCF;    
    }
    

    /**
     * Trigger from the parent MultiOperation to process the current resultset.
     * 
     * @param resultSet
     * @param resultStage
     * @return
     */
    @Override
    public CompletionStage<T>  setResultSet(ResultSet resultSet, CompletionStage<T> resultStage) {
      checkCanceled();
      if(!rowsHandler)
        initRowOperationResultSet(jdbcStatement, resultSet);
      else
        rowsHandlerResultSet = resultSet; // Use after RowOpertaion.submit() get called from RowHandler.
      
      resultCF.complete(null);
      
      if(!rowsHandler) {
        return resultStage
               .thenCompose(this::moreRows);
      }
      else
        return resultStage; // Call moreRows after RowHandler.submit() get called from the RowHandler. 
    }
    
    /**
     * Call moreRows after RowHandler.submit() get called from the RowHandler.
     * 
     * @return
     */
    CompletionStage<T>  setRowHandlerResultSet() {
      checkCanceled();
      if(rowsHandler) {
        initRowOperationResultSet(jdbcStatement, rowsHandlerResultSet);
        return resultStage
             .thenCompose(this::moreRows);
      }
      else
        return null;
    }
    
    /**
     * Wait for child operation complete the current result.
     * 
     * @param x Ignored
     * @return completion stage of the child operation.
     */
    public CompletionStage<T> resultProcessed(Object x) {
      checkCanceled();
      return opCompletetionStage;    
    }
    
    
    @Override
    T completeQuery() {
      T rc = super.completeQuery();
      
      // Trigger to move on to next resultset
      ((CompletableFuture)opCompletetionStage).complete(rc);
      
      return rc;
    }
    
    @Override
    protected void JdbcClose() {
      // Do nothing. Prevent closing of the parent JdbcStatement.
    }
    
    @Override
    protected void JdbcCancel() {
      // TODO
    }
  } // MultiRowOperation
   
   /**
    *  Child row publisher operation class.
    *  It waits for operation to submit, then add in the operation queue.
    *  Then it waits for parent MultiOperation gives the resultset.
    *  Once it receives the resultset, process it using a row publisher operation.
    *  Then complete the current resultset stage, so parent operation continue
    *  to next stage. It also returns child operation completion stage to the application.
    *
    * @param <T>
    */
    class MultiRowPublisherOperation<T> extends com.oracle.adbaoverjdbc.RowPublisherOperation<T>
                                        implements ChildRowOperation<T> {
     private CompletableFuture<T> resultCF;
     private long rowCount;
     private CompletionStage<T> opCompletetionStage;
     
     MultiRowPublisherOperation(Session session, OperationGroup operationGroup) {
       super(session, operationGroup, null);
       resultCF = new CompletableFuture<T>();
       rowCount = -1;
       opCompletetionStage = new CompletableFuture<T>();
     }
     
     @Override
     public Submission<T> submit() {
       Submission<T>  submission = super.submit();
       return new MultiOperationChildSubmission(submission, opCompletetionStage);
     }
     
     @Override
     CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
       addInResultQueue(null);
       predecessor
               .thenComposeAsync(this::resultExist, executor);
       
       return (CompletionStage<T>)predecessor;
     }

     /**
      * Add the child operation in the parent operation queue.
      * 
      * @param x
      * @return
      */
     private CompletionStage<T> addInResultQueue(Object x) {
       checkCanceled();
       resultOperations.add(this);
       return null;    
     }

     /**
      * Wait for parent MultiOperation trigger with resultset.
      * 
      * @param x
      * @return
      */
     private CompletionStage<T> resultExist(Object x) {
       checkCanceled();
       return resultCF;    
     }
     
     /**
      * Trigger from the parent MultiOperation to process the current resultset.
      * 
      * @param resultSet
      * @param resultStage
      * @return
      */
     @Override
     public CompletionStage<T>  setResultSet(ResultSet resultSet, CompletionStage<T> resultStage) {
       checkCanceled();
       initRowOperationResultSet(jdbcStatement, resultSet);      
       resultCF.complete(null);
       
       return resultStage
              .thenCompose(this::moreRows);
     }
     
     /**
      * Wait for child operation complete the current result.
      * 
      * @param x Ignored
      * @return completion stage of the child operation.
      */
     public CompletionStage<T> resultProcessed(Object x) {
       checkCanceled();
       return opCompletetionStage;    
     }
     
     
     @Override
     T completeQuery() {
       T rc = super.completeQuery();
       
       // Trigger to move on next result
       ((CompletableFuture)opCompletetionStage).complete(rc);
       
       return rc;
     }
     
     @Override
     protected void JdbcClose() {
       // Do nothing. Prevent closing of the JdbcStatement.
     }
     
     @Override
     protected void JdbcCancel() {
       // TODO
     }
   } // MultiRowOperation
   
   /**
    * Handling child operation completion stage.
    * In MultiOperation, there will be one MultiOperation completion stage
    * and one or more child operation completion stage.
    * 
    *
    * @param <T>
    */
   class MultiOperationChildSubmission<T> implements jdk.incubator.sql2.Submission<T> {
     
     Submission<T>  submission;
     CompletionStage<T> childOpCompletetionStage;
     
     MultiOperationChildSubmission(Submission<T> submission, CompletionStage<T> opCompletetionStage) {
       this.submission = submission;
       this.childOpCompletetionStage =  opCompletetionStage;
     }
     
     @Override
     public CompletionStage<Boolean> cancel() {
       return submission.cancel();
     }
     
     @Override
     public CompletionStage<T> getCompletionStage() {
       return ((CompletableFuture)childOpCompletetionStage).minimalCompletionStage();
     }
   } // MultiOperationChildSubmission
}
