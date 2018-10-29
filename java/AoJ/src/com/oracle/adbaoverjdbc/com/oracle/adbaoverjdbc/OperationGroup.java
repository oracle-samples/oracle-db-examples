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

import jdk.incubator.sql2.LocalOperation;
import jdk.incubator.sql2.MultiOperation;
import jdk.incubator.sql2.ParameterizedRowOperation;
import jdk.incubator.sql2.Submission;
import jdk.incubator.sql2.TransactionOutcome;
import java.time.Duration;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.function.Consumer;
import java.util.logging.Level;
import java.util.logging.Logger;
import java.util.stream.Collector;
import jdk.incubator.sql2.ParameterizedRowCountOperation;
import jdk.incubator.sql2.ParameterizedRowPublisherOperation;
import jdk.incubator.sql2.ArrayRowCountOperation;
import jdk.incubator.sql2.TransactionCompletion;

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

  static <U, V> OperationGroup<U, V> newOperationGroup(Session session) {
    return new OperationGroup<U, V>(session, session);
  }
  
  static final Logger NULL_LOGGER = Logger.getAnonymousLogger();
  static {
    NULL_LOGGER.setFilter(r -> false);
    NULL_LOGGER.setLevel(Level.SEVERE);
  }
  
  static final CompletionStage<Boolean> DEFAULT_CONDITION = CompletableFuture.completedFuture(true);
  
  private boolean isParallel = false;
  private boolean isIndependent = false;
  private CompletionStage<Boolean> condition = DEFAULT_CONDITION;
  
  private Object accumulator;
  private Collector collector;
  private volatile boolean hasCreatedMember = false;
  Logger logger = NULL_LOGGER;
  
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
  
  // used only by Session. Will break if used by any other class.
  protected OperationGroup() {
    super();
    held = new CompletableFuture();
    head = new CompletableFuture();
    memberTail = head;
    collector = DEFAULT_COLLECTOR;
  }
  
  protected OperationGroup(Session session, OperationGroup<? super T, ?> group) {
    super(session, group);
    held = new CompletableFuture();
    head = new CompletableFuture();
    memberTail = head;
    collector = DEFAULT_COLLECTOR;
  }
  
  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> parallel() {
    assertOpen();
    assertUnsubmitted();
    assertNoMembers();
    if (isParallel) 
      throw new IllegalStateException("Multiple calls to parallel()");
    isParallel = true;
    return this;
  }

  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> independent() {
    assertOpen();
    assertUnsubmitted();
    assertNoMembers();
    if (isIndependent)
      throw new IllegalStateException("Multiple calls to independent()");
    isIndependent = true;
    return this;
  }

  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> conditional(
    CompletionStage<Boolean> condition) {
    assertOpen();
    assertUnsubmitted();
    assertNoMembers();
    if (this.condition != DEFAULT_CONDITION) {
      throw new IllegalStateException(
        "Multiple calls to conditional(CompletionStage<Boolean>)");
    }
    this.condition = condition;
    return this;
  }

  @Override
  public Submission<T> submit() {
    assertOpen();
    assertUnsubmitted();
    operationLifecycle = OperationLifecycle.HELD;
    accumulator = collector.supplier().get();
    return group.submit(this);
  }

  @Override
  public void close() {
    assertOpen();
    held.complete(null);
    immutable();
  }

  @Override
  public OperationGroup<S, T> collect(Collector<S, ?, T> c) {
    assertOpen();
    assertUnsubmitted();
    if (collector != DEFAULT_COLLECTOR) {
      throw new IllegalStateException(
        "Multiple calls to collect(Collector<S, ?, T>");
    }
    if (c == null) throw new IllegalArgumentException("Null argument.");
    collector = c;
    return this;
  }
  
  @Override
  public Operation<S> catchOperation() {
    assertOpen();
    return addMember(UnskippableOperation.newOperation(session, this, 
                                                       op -> null));
  }

  @Override
  public <R extends S> ArrayRowCountOperation<R> arrayRowCountOperation(String sql) {
    assertOpen();
    if (sql == null) throw new IllegalArgumentException("Null argument.");
    return addMember(ArrayCountOperation.newArrayCountOperation(session, 
                                                                this, sql));
  }

  @Override
  public <R extends S> ParameterizedRowCountOperation<R> rowCountOperation(String sql) {
    assertOpen();
    if (sql == null) throw new IllegalArgumentException("Null argument.");
    return addMember(CountOperation.newCountOperation(session, this, sql));
 }

  @Override
  public SqlOperation<S> operation(String sql) {
    assertOpen();
    if (sql == null) throw new IllegalArgumentException("Null argument.");
    return addMember(SqlOperation.newOperation(session, this, sql));
  }

  @Override
  public <R extends S> jdk.incubator.sql2.OutOperation<R> outOperation(String sql) {
    assertOpen();
    if (sql == null) throw new IllegalArgumentException("TODO");
    return addMember(OutOperation.newOutOperation(session, this, sql));
  }

  @Override
  public <R extends S> ParameterizedRowOperation<R> rowOperation(String sql) {
    assertOpen();
    if (sql == null) throw new IllegalArgumentException("Null argument.");
    return addMember(RowOperation.newRowOperation(session, this, sql));
  }

  @Override
  public <R extends S> ParameterizedRowPublisherOperation<R> rowPublisherOperation(String sql) {
    assertOpen();
    if (sql == null) throw new IllegalArgumentException("TODO");
    return addMember(RowPublisherOperation.newRowPublisherOperation(
                        session, this, sql));
  }

  @Override
  public <R extends S> MultiOperation<R> multiOperation(String sql) {
    assertOpen();
    if (sql == null) throw new IllegalArgumentException("TODO");
    return com.oracle.adbaoverjdbc.MultiOperation.newMultiOperation(session, this, sql);
  }

  @Override
  public SimpleOperation<TransactionOutcome> endTransactionOperation(TransactionCompletion trans) {
    assertOpen();
    // TODO If member type S != TransactionOutcome ???
    SimpleOperation<TransactionOutcome> newOp = 
      SimpleOperation.<TransactionOutcome>newOperation(session, 
        (OperationGroup<Object,T>)this, 
        op -> session.jdbcEndTransaction(op, 
                        (com.oracle.adbaoverjdbc.TransactionCompletion)trans)
        );
    addMember((Operation<S>)newOp);
    return newOp;
  }

  @Override
  public <R extends S> LocalOperation<R> localOperation() {
    assertOpen();
    return addMember(
      com.oracle.adbaoverjdbc.LocalOperation.newOperation(session, this));
  }

  @Override
  public jdk.incubator.sql2.OperationGroup<S, T> logger(Logger logger) {
    if ( logger == null ) throw new NullPointerException("OperationGroup.logger");
    else this.logger = logger;
    return this;
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
  
  
  // Internal methods
  
  Submission<S> submit(Operation<S> op) {      
    memberTail = op.attachCompletionHandler(op.follows(memberTail, getExecutor()));
    return com.oracle.adbaoverjdbc.Submission.submit(this::cancel, memberTail);
  }

  @Override
  CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
    return predecessor.thenCompose(r -> 
      condition.exceptionally(condErr -> false)
        .thenCompose(cond -> {
          if (cond == null || !cond) 
            return CompletableFuture.completedFuture(null);
        
          head.complete(predecessor);
          return held.thenCompose(h -> memberTail.thenApplyAsync(t -> 
                                         (T)collector.finisher()
                                           .apply(accumulator),
                                         executor));
        })
      );
  }
  
  /**
   * Accumulate the result of a member operation with this group's collector.
   * @param memberResult The result of a member operation.
   */
  void accumulateResult(S memberResult) {
    collector.accumulator()
      .accept(accumulator, memberResult);
  }
  
  /**
   * @throws IllegalStateException If this OperationGroup has been closed.
   */
  protected void assertOpen() {
    if (isImmutable()) 
      throw new IllegalStateException("OperationGroup is closed.");
  }
  
  /**
   * @throws IllegalStateException If this OperationGroup has been submitted.
   */
  private void assertUnsubmitted() {
    if (operationLifecycle.isSubmitted()) 
      throw new IllegalStateException("OperationGroup is submitted.");
  }
  
  /**
   * @throws IllegalStateException If this OperationGroup has created any 
   *   member operations.
   */
  private void assertNoMembers() {
    if (hasCreatedMember) 
      throw new IllegalStateException("OperationGroup has created members.");
  }
  
  /**
   * Register a member operation which has been created by this 
   * OperationGroup. 
   * @param member An operation created by this group.
   * @return The same instance which was provided as the <code>member</code> 
   *   argument. 
   */
  protected <U extends Operation<? extends S>> U addMember(U member) {
    hasCreatedMember = true;
    return member;
  }
}
