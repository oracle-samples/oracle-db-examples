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

import jdk.incubator.sql2.ArrayCountOperation;
import jdk.incubator.sql2.DynamicMultiOperation;
import jdk.incubator.sql2.LocalOperation;
import jdk.incubator.sql2.OutOperation;
import jdk.incubator.sql2.ParameterizedCountOperation;
import jdk.incubator.sql2.ParameterizedRowOperation;
import jdk.incubator.sql2.RowProcessorOperation;
import jdk.incubator.sql2.StaticMultiOperation;
import jdk.incubator.sql2.Submission;
import jdk.incubator.sql2.Transaction;
import jdk.incubator.sql2.TransactionOutcome;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.concurrent.Flow;
import java.util.function.Consumer;
import java.util.logging.Logger;
import java.util.stream.Collector;

/**
 * Only sequential, dependent, unconditional supported.
 * 
 * Each member Operation creates a CompletableFuture that depends on the previous
 * member's CompletableFuture. The first member Operation depends on a distinguished
 * CompletableFuture called the head. When the head is completed
 * the chain of member Operations is executed asynchronously. 
 * 
 * When the OperationGroup itself is submitted, the head is completed with
 * the predecessor CompletableFuture. So, when the preceding Operation is completed
 * the head is completed and the member Operations begin execution.
 * 
 * The CompletableFuture for the OperationGroup depends on a CompletableFuture 
 * called held. When held is complete no more member Operations can be added. The
 * value of the OperationGroup's CompletableFuture is computed by creating another
 * CompletableFuture that depends on the value of the last member Operation. Since
 * this is created only after held is completed we know the last member Operation.
 * 
 * When the last member Operation is completed the result of the OperationGroup is
 * computed by applying collector.finisher to the accumulator.
 * 
 * For parallel groups each member Operation should depend directly on the
 * head and the OperationGroup's result should depend on all the member
 * Operations.
 * 
 * For independent groups follows needs to insure the returned CompletableFuture
 * hides any exceptions.
 * 
 * For conditional groups the head should depend on both the predecessor
 * completing and the condition completing with true.
 *
 * @param <S> value type of member Operations
 * @param <T> value type of OperationGroup
 */
class OperationGroup<S, T> extends com.oracle.adbaoverjdbc.Operation<T> 
        implements jdk.incubator.sql2.OperationGroup<S, T> {
  
  static final Collector DEFAULT_COLLECTOR = Collector.of(
          () -> null,
          (a, v) -> {},
          (a, b) -> null,
          a -> null);

  static <U, V> OperationGroup<U, V> newOperationGroup(Connection conn) {
    return new OperationGroup(conn, conn);
  }
  
  private boolean isParallel = false;
  private boolean isIndependent = false;
  private CompletionStage<Boolean> condition = null;
  
  private Object accumulator;
  private Collector collector;
  
/** 
   * completed when this OperationGroup is no longer held. Completion of this
   * OperationGroup depends on held.
   * 
   * @see submit, releaseProhibitingMoreOperations, submitHoldingForMoreOperations
   */
  private final CompletableFuture<S> held;
  
  /**
   * predecessor of all member Operations and the OperationGroup itself
   */
  private final CompletableFuture head;
  
  /**
   * The last CompletionStage of any submitted member Operation. Mutable until
   * not isHeld().
   */
  private CompletionStage<S> memberTail;
  
  protected OperationGroup(Connection conn, OperationGroup<? super T, ?> group) {
    super(conn, group);
    held = new CompletableFuture();
    head = new CompletableFuture();
    memberTail = head;
    collector = DEFAULT_COLLECTOR;
  }
  
  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> parallel() {
    if ( isImmutable() || isParallel) throw new IllegalStateException("TODO");
    isParallel = true;
    return this;
  }

  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> independent() {
    if ( isImmutable() || isIndependent) throw new IllegalStateException("TODO");
    isIndependent = true;
    return this;
  }

  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> conditional(CompletionStage<Boolean> condition) {
    if ( isImmutable() || condition != null) throw new IllegalStateException("TODO");
    this.condition = condition;
    return this;
  }

  @Override
  public jdk.incubator.sql2.Submission<T> submitHoldingForMoreMembers() {
    if ( isImmutable() || ! isHeld() ) throw new IllegalStateException("TODO");  //TODO prevent multiple calls
    accumulator = collector.supplier().get();
    return super.submit();
  }

  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> releaseProhibitingMoreMembers() {
    if ( ! isImmutable() || ! isHeld() ) throw new IllegalStateException("TODO");
    held.complete(null);
    immutable();  // having set isHeld to false this call will make this OpGrp immutable
    return this;
  }

  @Override
  public OperationGroup<S, T> collect(Collector<S, ?, T> c) {
    if ( isImmutable() || collector != DEFAULT_COLLECTOR) throw new IllegalStateException("TODO");
    if (c == null) throw new IllegalArgumentException("TODO");
    collector = c;
    return this;
  }
  
  @Override
  public Operation<S> catchOperation() {
    if (! isHeld() ) throw new IllegalStateException("TODO");
    return UnskippableOperation.newOperation(connection, this, op -> null);
  }

  @Override
  public <R extends S> ArrayCountOperation<R> arrayCountOperation(String sql) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public <R extends S> ParameterizedCountOperation<R> countOperation(String sql) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
     if (sql == null) throw new IllegalArgumentException("TODO");
    return CountOperation.newCountOperation(connection, this, sql);
 }

  @Override
  public SqlOperation<S> operation(String sql) {
    if ( !isHeld() ) throw new IllegalStateException("TODO");
    return SqlOperation.newOperation(connection, this, sql);
  }

  @Override
  public <R extends S> OutOperation<R> outOperation(String sql) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public <R extends S> ParameterizedRowOperation<R> rowOperation(String sql) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    if (sql == null) throw new IllegalArgumentException("TODO");
    return RowOperation.newRowOperation(connection, this, sql);
  }

  @Override
  public <R extends S> RowProcessorOperation<R> rowProcessorOperation(String sql) {
    if ( !isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public <R extends S> StaticMultiOperation<R> staticMultiOperation(String sql) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public <R extends S> DynamicMultiOperation<R> dynamicMultiOperation(String sql) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public SimpleOperation<TransactionOutcome> endTransactionOperation(Transaction trans) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    return com.oracle.adbaoverjdbc.SimpleOperation.<TransactionOutcome>newOperation(
              connection, 
              (OperationGroup<Object,T>)this, 
              op -> connection.jdbcEndTransaction(op, (com.oracle.adbaoverjdbc.Transaction)trans));
  }

  @Override
  public <R extends S> LocalOperation<R> localOperation() {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public <R extends S> Flow.Processor<jdk.incubator.sql2.Operation<R>, Submission<R>> operationProcessor() {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> logger(Logger logger) {
    if ( ! isHeld() ) throw new IllegalStateException("TODO");
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public OperationGroup<S, T> timeout(Duration minTime) {
    super.timeout(minTime);
    return this;
  }

  @Override
  public OperationGroup<S, T> onError(Consumer<Throwable> handler) {
    super.onError(handler);
    return this;
  }
  
  @Override
  public Submission<T> submit() {
    if ( isImmutable() ) throw new IllegalStateException("TODO");
    accumulator = collector.supplier().get();
    held.complete(null);
    return super.submit();
  }

  // Internal methods
  
  Submission<S> submit(Operation<S> op) {
    memberTail = op.attachErrorHandler(op.follows(memberTail, getExecutor()));
    return com.oracle.adbaoverjdbc.Submission.submit(this::cancel, memberTail);
  }

  @Override
  CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
    head.complete(predecessor); // completing head allows members to execute
    return held.thenCompose( h -> // when held completes memberTail holds the last member
            memberTail.thenApplyAsync( t -> (T)collector.finisher().apply(accumulator), executor));
  }
  
  protected boolean isHeld() {
    return !held.isDone();
  }
      
}
