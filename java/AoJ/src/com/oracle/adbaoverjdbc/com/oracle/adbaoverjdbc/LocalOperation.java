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

import java.time.Duration;
import java.util.concurrent.Callable;
import java.util.concurrent.atomic.AtomicReference;
import java.util.function.Consumer;

import jdk.incubator.sql2.Session.Lifecycle;
import jdk.incubator.sql2.Session.SessionLifecycleListener;

class LocalOperation<T> extends SimpleOperation<T> 
  implements jdk.incubator.sql2.LocalOperation<T> {

  /** 
   * Describes the state of execute() in terms of whether its currently 
   * executing, or if the executing thread was interrupted as a result of
   * calling the interrupt().
   */ 
  private enum ExecutionState { NOT_EXECUTING, EXECUTING, INTERRUPTED };
  
  private static final Callable<?> DEFAULT_ACTION = () -> null;
  
  /** A user specified action */
  private Callable<T> action;
     
  /** 
   * A reference to this operation's state in regards to executing on a 
   * thread. This object is accessed by interrupt() and execute() threads. 
   */
  private final AtomicReference<ExecutionState> stateRef;

  /** 
   * The thread which execute() is running on. The reference is published by
   * a thread calling execute() and accessed by a thread calling interrupt().
   * For this reason, the field is declared volatile.
   */
  private volatile Thread executingThread = null;
  
  
  /** 
   * Upon session abort, this listener interrupts any thread which is 
   * executing the user defined action. 
   */
  private SessionLifecycleListener abortListener;

  @SuppressWarnings("unchecked")
  private LocalOperation(Session session,
                         OperationGroup<? super T, ?> operationGroup) {
    super(session, operationGroup, 
          thisOp -> ((LocalOperation<T>)thisOp).execute());
    action = (Callable<T>) DEFAULT_ACTION;
    stateRef = new AtomicReference<>(
                 ExecutionState.NOT_EXECUTING);
  }
  
  static <S, R extends S> LocalOperation<R> newOperation(
    Session session, OperationGroup<S, ?> group) {
    return new LocalOperation<>(session, group);
  }
  
  @Override
  public LocalOperation<T> onExecution(Callable<T> action) {
    
    if (isImmutable())
      throw new IllegalStateException("This operation is submitted.");


    if (action == null)
      throw new IllegalArgumentException("Null action");
    
    if (this.action != DEFAULT_ACTION) {
      throw new IllegalStateException(
        "Mutliple invocations of onExecution(Callable)");
    }
    
    this.action = action;
    return this;
  }
  
  @Override
  public LocalOperation<T> onError(Consumer<Throwable> handler) {
    return (LocalOperation<T>) super.onError(handler);
  }

  @Override
  public LocalOperation<T> timeout(Duration minTime) {
    return (LocalOperation<T>) super.timeout(minTime);
  }
  
  @Override
  public jdk.incubator.sql2.Submission<T> submit() {
    registerAbortListener();
    return super.submit();
  }
  
  private void registerAbortListener() {
    assert abortListener == null;
    
    abortListener = (jdk.incubator.sql2.Session session1, Lifecycle previous, Lifecycle current) -> {
        if (Lifecycle.ABORTING == current)
            interrupt();  
    };
    
    session.registerLifecycleListener(abortListener);
  }
  
  private void deregisterAbortListener() {
    assert abortListener != null;
    session.deregisterLifecycleListener(abortListener);
  }
  
  /**
   * Interrupt the execution of this local operation by setting the interrupt
   * status on a currently executing thread. If the operation is not currently 
   * executing, an eventual execution will return null rather than invoking
   * any action which was defined for this operation.
   */ 
  void interrupt() {
    stateRef.getAndUpdate(cur -> {
      if (ExecutionState.EXECUTING == cur)
        executingThread.interrupt();
      
      return ExecutionState.INTERRUPTED;
    });
  }

  /**
   * Execute the user defined action.
   * 
   * Note the importance of calling Thread.interrupt() before this method
   * returns. Under no circumstances should the thread be returned to a pool
   * with it's interrupt status set. This may lead to failure when another
   * runnable is executed on the pooled thread.
   * @return The return value of the user specified action, or null if the
   *   execution state has been set to INTERRUPTED.
   */
  private T execute() {
    assert executingThread == null;
    
    try { 
      executingThread = Thread.currentThread();
      return stateRef.compareAndSet(ExecutionState.NOT_EXECUTING, 
                                    ExecutionState.EXECUTING)
             ? action.call()
             : null;
    }
    catch (Exception e) { 
      throw new RuntimeException(e); 
    }
    finally {
      if (ExecutionState.INTERRUPTED == 
            stateRef.getAndSet(ExecutionState.NOT_EXECUTING)) {
        Thread.interrupted();
      }
      
      executingThread = null;
      deregisterAbortListener();
    }
  }
}
