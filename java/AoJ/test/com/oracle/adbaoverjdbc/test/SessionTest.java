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
package com.oracle.adbaoverjdbc.test;

import jdk.incubator.sql2.AdbaSessionProperty;
import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.Operation;
import jdk.incubator.sql2.OperationGroup;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.Session.Builder;
import jdk.incubator.sql2.Session.Lifecycle;
import jdk.incubator.sql2.Session.SessionLifecycleListener;
import jdk.incubator.sql2.Session.Validation;
import jdk.incubator.sql2.Submission;
import jdk.incubator.sql2.TransactionCompletion;
import jdk.incubator.sql2.TransactionOutcome;
import jdk.incubator.sql2.AdbaSessionProperty.TransactionIsolation;

import static org.junit.Assert.assertArrayEquals;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;
import static org.junit.Assert.fail;

import java.util.List;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.function.Function;
import java.util.stream.Collectors;

import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import com.oracle.adbaoverjdbc.test.SessionTest.TestLifecycleListener.LifecycleEvent;

import static com.oracle.adbaoverjdbc.test.TestConfig.*;

/**
 * Verifies the public API of Session and Session.Builder function as 
 * described in the ADBA javadoc.
 */
public class SessionTest {
  
  private static final String TRANSACTION_TABLE = "AOJ_TRANSACTION_TEST";
  private static final String ABORT_TABLE_1= "AOJ_ABORT_TEST_1";
  private static final String ABORT_TABLE_2 = "AOJ_ABORT_TEST_2";
  private static final String OP_GROUP_TABLE = "AOJ_OP_GROUP_TEST";

  @BeforeClass
  public static void createTestTables() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      se.operation("CREATE TABLE " + TRANSACTION_TABLE + " (c CHAR(1))")
        .submit();
      se.operation("CREATE TABLE " + ABORT_TABLE_1 + " (c CHAR(1))")
        .submit();
      se.operation("CREATE TABLE " + ABORT_TABLE_2 + " (c CHAR(1))")
        .submit();
      se.operation("CREATE TABLE " + OP_GROUP_TABLE + " (c INTEGER)")
        .submit();
      se.endTransactionOperation(se.transactionCompletion())
        .timeout(getTimeout())
        .onError(err -> err.printStackTrace())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }

  @AfterClass
  public static void dropTestTables() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      se.operation("DROP TABLE " + TRANSACTION_TABLE)
        .submit();
      se.operation("DROP TABLE " + ABORT_TABLE_1)
        .submit();
      se.operation("DROP TABLE " + ABORT_TABLE_2)
        .submit();
      se.operation("DROP TABLE " + OP_GROUP_TABLE)
        .submit();
      se.endTransactionOperation(se.transactionCompletion())
        .timeout(getTimeout())
        .onError(err -> err.printStackTrace())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }
  
  /**
   * Verifies the following behavior: 
   * <br>
   * (1) Session.Builder.property(SessionProperty, Object) will specify a 
   * property and its value for the built Session. 
   * [Spec: {@link Session.Builder#property(SessionProperty, Object)}]
   * Session.getProperties() will return the set of properties configured on 
   * this Session excepting any sensitive properties. 
   * [Spec: {@link Session#getProperties()}]
   * <br>
   * (2) A Session is initially in the Session.Lifecycle.NEW lifecycle state. 
   * [Spec: {@link Session.Builder}]
   * <br>
   * (3) If an attach operation completes successfully and the lifecycle is 
   * Session.Lifecycle.NEW -> Session.Lifecycle.OPEN. 
   * [Spec: {@link Session#attachOperation()}]
   * <br>
   * (4) Session.getSessionLifecycle() returns the current lifecycle of this 
   * Session. [Spec: {@link Session#getSessionLifecycle()}]
   * <br> 
   * (5) Session.registerLifcycleListener(SessionLifecycleListener) registers
   * a listener that will be called whenever there is a change in the 
   * lifecycle of this Session. If the listener is already registered this 
   * is a no-op. [Spec: 
   * {@link Session#registerLifecycleListener(SessionLifecycleListener)}]
   * (6) Session.closeOperation() returns an operation which, upon execution, 
   * transitions the session's lifecyle from OPEN to CLOSING. When the 
   * operation completes, and no other operations are enqueued, the lifecycle
   * transistions from CLOSING to CLOSED. If the operation is submitted when 
   * the lifecycle is closed, the execution of the operation is a no-op. 
   * [Spec: {@link Session#closeOperation()}] 
   */
  @Test
  public void testSessionBuilder() throws Exception {
    
    TestLifecycleListener testListener = new TestLifecycleListener(); 
    
    final String url = getUrl();
    final String user = getUser();
    final String password = getPassword();
    
    Session se = DataSourceFactory.newFactory(getDataSourceFactoryName())
                        .builder().build().builder()
                        .property(AdbaSessionProperty.URL, url)
                        .property(AdbaSessionProperty.USER, user)
                        .property(AdbaSessionProperty.PASSWORD, password)
                        .build();
      
      // (1)
      assertEquals(url, se.getProperties().get(AdbaSessionProperty.URL)); 
      assertEquals(user, se.getProperties().get(AdbaSessionProperty.USER));
      assertNull(se.getProperties().get(AdbaSessionProperty.PASSWORD));

      // (2, 4)
      assertEquals(Lifecycle.NEW, se.getSessionLifecycle());

      // (5)
      // The duplicate call verifies the no-op behavior. 
      se.registerLifecycleListener(testListener);
      se.registerLifecycleListener(testListener);
      
      // (3, 4)
      se.submit();
      se.attachOperation()
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
      assertEquals(Lifecycle.ATTACHED, se.getSessionLifecycle());
      
      // (4, 6)
      se.closeOperation()
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
      assertEquals(Lifecycle.CLOSED, se.getSessionLifecycle());

      // (6) 
      // The duplicate close operation verifies the no-op behavior.
      se.closeOperation()
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
      
      // (2, 3, 5, 6)
      LifecycleEvent[] expected = {
        new LifecycleEvent(se, Lifecycle.NEW, Lifecycle.ATTACHED),
        new LifecycleEvent(se, Lifecycle.ATTACHED, Lifecycle.CLOSING),
        new LifecycleEvent(se, Lifecycle.CLOSING, Lifecycle.CLOSED),
      };
      LifecycleEvent[] actual = 
        testListener.record.toArray(new LifecycleEvent[0]);
      assertArrayEquals(expected, actual);
  }

  /**
   * Verifies the following behavior:
   * <br>
   * (1) A Session transitions to Session.Lifecycle.CLOSED if initialization 
   * fails.[Spec: {@link Session.Builder}]
   * @throws java.lang.Exception
   */
  @Test
  public void testAttachFailure() throws Exception {
    
    class ErrorFunction implements Function<Throwable, Void> {
      Throwable applied = null;
      
      @Override
      public Void apply(Throwable err) { 
        applied = err; 
        return null; 
      }
    }
    ErrorFunction errFn = new ErrorFunction();
    
    // Use an invalid URL to cause attach operation failure. 
    final String url = "jdbc:oracle:slim:@localhost:5521";
    final String user = getUser();
    final String password = getPassword();
    
    try (Session se = DataSourceFactory.newFactory(getDataSourceFactoryName())
                        .builder().build().builder()
                        .property(AdbaSessionProperty.URL, url)
                        .property(AdbaSessionProperty.USER, user)
                        .property(AdbaSessionProperty.PASSWORD, password)
                        .build()) {
      // (1)
      se.submit();
      se.attachOperation().timeout(getTimeout()).submit()
        .getCompletionStage().exceptionally(errFn).toCompletableFuture().get();
      assertNotNull(errFn.applied);
      assertEquals(Lifecycle.CLOSED, se.getSessionLifecycle());
    }
  }

  /**
   * Verifies the following behavior:
   * <br>
   * (1) Session.localOperation() returns a an Operation that executes a user
   * defined action when executed. 
   * [Spec: {@link Session#localOperation}, {@link jdk.incubator.sql2.LocalOperation}]
   * @throws TimeoutException 
   * @throws ExecutionException 
   * @throws InterruptedException 
   */
  @Test
  public void testLocalOperation() throws Exception {
    final String expected = "Result of local operation";
    
    try (Session se = DataSourceFactory.newFactory(getDataSourceFactoryName())
      .builder().url(getUrl()).username(getUser()).password(getPassword())
      .build().getSession()) {
      Object actual = se.localOperation()
                        .onExecution(() -> expected)
                        .timeout(getTimeout())
                        .submit()
                        .getCompletionStage()
                        .toCompletableFuture()
                        .get();
      assertEquals(expected, actual);
    }
  }
  
  /**
   * Verifies the following behavior:
   * (1) Session.rowCountOperation returns a new
   * ParameterizedRowCountOperation.
   * [Spec: {@link Session#rowCountOperation(String)}]
   * <br>
   * (2) Session.transactionCompletion() returns a new TransactionCompletion
   * [Spec: {@link Session#transactionCompletion()}
   * <br>
   * (3) Session.commitMaybeRollback(TransactionCompletion) returns a
   * CompletionStage that is completed with the outcome of the transaction.
   * [Spec:
   * {@link Session#commitMaybeRollback(jdk.incubator.sql2.TransactionCompletion)}]
   * <br>
   * (4) Session.rowOperation(String) returns a new
   * ParameterizedRowCountOperation
   * [Spec: {@link Session#rowOperation(String)}]
   * <br>
   * (5) Session.commitMaybeRollback(TransactionCompletion) submits an
   * operation which commits or rolls back the current transaction.
   * [Spec:
   * {@link Session#commitMaybeRollback(jdk.incubator.sql2.TransactionCompletion)}]
   * <br>
   * (6) Session.endTransactionOperation(TransactionCompletion) returns a new
   * Operation that ends the database transaction. This Operation is a member of
   * the OperationGroup. The transaction is ended with a commit unless the
   * TransactionCompletion has been TransactionCompletion.setRollbackOnly in
   * which case the transaction is ended with a rollback.
   * [Spec: {@link Session#endTransactionOperation(TransactionCompletion)}]
   * 
   * @throws Exception
   */
  @Test
  public void testTransaction() throws Exception {
    DataSource ds = DataSourceFactory.newFactory(getDataSourceFactoryName())
      .builder()
      .url(getUrl())
      .username(getUser())
      .password(getPassword())
      .sessionProperty(AdbaSessionProperty.TRANSACTION_ISOLATION, 
                       TransactionIsolation.READ_COMMITTED)
      .build();
    
    try (Session se = ds.getSession()) {

      // (1)
      long insertCount = se.<Long>rowCountOperation(
           "INSERT INTO " + TRANSACTION_TABLE + " VALUES ('a')")
        .apply((rowCount)->rowCount.getCount())
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
      assertNotNull(insertCount);
      assertEquals(1L, insertCount);
      
      // (3, 4)
      TransactionOutcome commitOutcome = 
        se.commitMaybeRollback(se.transactionCompletion())
          .toCompletableFuture()
          .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
      assertEquals(TransactionOutcome.COMMIT, commitOutcome);
      
      // Committed changes will be visible to other sessions
      try (Session se2 = ds.getSession()) {
        
        // (5, 6)
        List<String> selectedRows = 
          se2.<List<String>>rowOperation("SELECT * FROM " + TRANSACTION_TABLE)
          .collect(Collectors.mapping((row) -> row.at(1).get(String.class), 
                                      Collectors.toList()))
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .get();
        assertNotNull(selectedRows);
        assertEquals(1, selectedRows.size());
        assertEquals("a", selectedRows.get(0));
        
        // (1)
        se2.rowCountOperation("INSERT INTO " + TRANSACTION_TABLE + " VALUES ('b')")
          .timeout(getTimeout())
          .submit();

        // (4)
        List<String> selectedRows2 = 
          se2.<List<String>>rowOperation("SELECT * FROM " + TRANSACTION_TABLE)
            .collect(Collectors.mapping((row) -> row.at(1).get(String.class), 
                                        Collectors.toList()))
            .timeout(getTimeout())
            .submit()
            .getCompletionStage()
            .toCompletableFuture()
            .get();
        assertNotNull(selectedRows2);
        assertEquals(2, selectedRows2.size());
        assertTrue(selectedRows2.contains("a"));
        assertTrue(selectedRows2.contains("b"));
        
        // (3, 7)
        TransactionCompletion rollbackInsert = se2.transactionCompletion();
        rollbackInsert.setRollbackOnly();
        TransactionOutcome rollbackOutcome = 
          se2.endTransactionOperation(rollbackInsert)
            .timeout(getTimeout())
            .submit()
            .getCompletionStage()
            .toCompletableFuture()
            .get();
        assertEquals(TransactionOutcome.ROLLBACK, rollbackOutcome);
      }
      
      List<String> selectedRows = 
        se.<List<String>>rowOperation("SELECT * FROM " + TRANSACTION_TABLE)
          .collect(Collectors.mapping((row) -> row.at(1).get(String.class), 
                                      Collectors.toList()))
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .get();
      assertNotNull(selectedRows);
      assertEquals(1, selectedRows.size());
      assertEquals("a", selectedRows.get(0));
    }
  }

/**
 * Verifies the following behavior:
 * <br>
 * (1) If lifecycle is Session.Lifecycle.NEW, Session.Lifecycle.OPEN,
 * Session.Lifecycle.INACTIVE or Session.Lifecycle.CLOSING ->
 * Session.Lifecycle.ABORTING.[Spec: {@link Session#abort()}]
 * <br>
 * (2) If lifecycle is Session.Lifecycle.ABORTING or Session.Lifecycle.
 * CLOSED this is a no-op. [Spec: {@link Session#abort()}]
 *
 * @throws java.lang.Exception
 */
  @Test
  public void testAbort() throws Exception {
    DataSource ds = DataSourceFactory.newFactory(getDataSourceFactoryName())
      .builder()
      .url(getUrl())
      .username(getUser())
      .password(getPassword())
      .sessionProperty(AdbaSessionProperty.TRANSACTION_ISOLATION, 
                       TransactionIsolation.SERIALIZABLE)
      .build();
    
    Session se1 = ds.builder()
                    .build();
    TestLifecycleListener se1LifecycleListener = new TestLifecycleListener();
    se1.registerLifecycleListener(se1LifecycleListener);
    Submission<?> se1Submission = se1.submit();
    se1.attachOperation()
      .submit();

    // Create a record which two sessions will try to update.
    se1.rowCountOperation("INSERT INTO " + ABORT_TABLE_1 + " VALUES ('a')")
      .submit();
    se1.commitMaybeRollback(se1.transactionCompletion());
    
    // Session 1 acquires a lock on the record.
    se1.rowCountOperation(
      "UPDATE " + ABORT_TABLE_1 + " SET c='b' WHERE c='a'")
      .submit();
    se1.<List<String>>rowOperation("SELECT * FROM " + ABORT_TABLE_1)
      .collect(Collectors.mapping(row -> row.at(1).get(String.class), 
                                  Collectors.toList()))
      .timeout(getTimeout())
      .submit()
      .getCompletionStage()
      .toCompletableFuture()
      .get();

    // Session 2 gets blocked acquiring a lock on the same record.
    Session se2 = ds.builder().build();
    Submission<?> se2Submission = se2.submit();
    se2.attachOperation()
      .submit();
    Submission<Long> blockedSubmission = 
      se2.<Long>rowCountOperation(
        "UPDATE " + ABORT_TABLE_1 + " SET c='z' WHERE c='a'")
        .apply(count -> count.getCount())
        .timeout(getTimeout())
        .submit();

    // Session 1 is aborted so that session 2 can proceed.
    se1.abort();
    se1.abort(); // (2)

    // (1)
    LifecycleEvent[] expectedEvents = {
      new LifecycleEvent(se1, Lifecycle.NEW, Lifecycle.ATTACHED),
      new LifecycleEvent(se1, Lifecycle.ATTACHED, Lifecycle.ABORTING),
      new LifecycleEvent(se1, Lifecycle.ABORTING, Lifecycle.CLOSED),
    };
    
    for (LifecycleEvent expected : expectedEvents) {
      LifecycleEvent actual = 
        se1LifecycleListener.record.poll(getTimeout().toMillis(), 
                                         TimeUnit.MILLISECONDS);
      if (actual == null)
        fail("Timeout waiting for lifecycle event: " + expected);

      assertEquals(expected, actual);
    }
    
    long unblockedResult =
       blockedSubmission.getCompletionStage()
         .toCompletableFuture()
         .get();
    assertEquals(1L, unblockedResult);
    se2.rollback();
    se2.close();

    se1Submission.getCompletionStage()
      .toCompletableFuture()
      .handle((r,e)-> {
        assertNotNull(e);
        return null;
      })
      .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    
    se2Submission.getCompletionStage()
      .toCompletableFuture()
      .handle((r,e)-> {
        assertNull(e);
        return null;
      })
      .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
  }
  
/**
 * Verifies the following behavior:
 * <br>
 * (1) Session.abort() terminates the currently executing operation.[Spec:
 * {@link Session#abort()}]. Note: This test assumes that the thread used to
 * execute a local operation would be interrupted, but this is not
 * explicitly stated in the spec.
 * <br>
 * (2) Session.abort() discards any queued local operations; Queued
 * operations are not executed or completed exceptionally. [Spec:
 * {@link Session#abort()}].
 *
 * @throws java.lang.Exception
 */
  @Test
  public void testAbortLocal() throws Exception {
    DataSource ds = DataSourceFactory.newFactory(getDataSourceFactoryName())
                      .builder()
                      .url(getUrl())
                      .username(getUser())
                      .password(getPassword())
                      .build();
    
    Session se = ds.getSession();
    CountDownLatch executingLatch = new CountDownLatch(1);
    CountDownLatch blockingLatch = new CountDownLatch(1);
    CountDownLatch exitLatch = new CountDownLatch(1);
    AtomicBoolean currentOpWasTerminated = new AtomicBoolean();
    
    se.<Void>localOperation()
      .onExecution(() -> {
        try {
          executingLatch.countDown();
          blockingLatch.await(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
        }
        catch (InterruptedException terminationSignal) { 
          currentOpWasTerminated.set(true);
        }
        finally{
          exitLatch.countDown();
        }
        return null;
      })
      .submit();
    
    AtomicBoolean queuedOpWasExecuted = new AtomicBoolean();
    se.localOperation()
      .onExecution( () -> {
        queuedOpWasExecuted.set(true);
        return null;
      })
      .submit();
    
    // Wait for the first local operation to begin execution, then abort().
    executingLatch.await(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    se.abort();
    exitLatch.await(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    assertTrue(currentOpWasTerminated.get());
    assertFalse(queuedOpWasExecuted.get());
  }

  /**
   * Verify that declaring a Session in try-with-resources closes the session
   * when the try block exits.
   * @throws Exception
   */
  @Test
  public void testTryWithResources() throws Exception {
    Builder sessionBuilder = 
      DataSourceFactory.newFactory(getDataSourceFactoryName())
        .builder()
        .url(getUrl())
        .username(getUser())
        .password(getPassword())
        .build()
        .builder();
    
    TestLifecycleListener listener = new TestLifecycleListener();
    LifecycleEvent[] expectedEvents;
    
    try (Session se = sessionBuilder.build()) {
      se.registerLifecycleListener(listener);
      se.submit();
      se.attachOperation()
        .timeout(getTimeout())
        .submit();

      expectedEvents = new LifecycleEvent[] {
        new LifecycleEvent(se, Lifecycle.NEW, Lifecycle.ATTACHED),
        new LifecycleEvent(se, Lifecycle.ATTACHED, Lifecycle.CLOSING),
        new LifecycleEvent(se, Lifecycle.CLOSING, Lifecycle.CLOSED),
      };
    }
    
    for (LifecycleEvent expected : expectedEvents) {      
      LifecycleEvent actual = listener.record.poll(getTimeout().toMillis(), 
                                                   TimeUnit.MILLISECONDS);
      if (actual == null)
        fail("Timeout waiting for lifecycle event: " + expected);

      assertEquals(expected, actual);
    }
    
    
  }

  /** Retains a record of all calls to lifecycleEvent */
  static class TestLifecycleListener implements SessionLifecycleListener {
    
    final BlockingQueue<LifecycleEvent> record = 
      new LinkedBlockingQueue<>();
    
    @Override
    public void lifecycleEvent(Session session, Lifecycle previous,
                               Lifecycle current) {
      LifecycleEvent event = new LifecycleEvent(session, previous, current);
      record.add(event);
    }
    
    /** Holds the arguments passed to lifcycleEvent */
    static class LifecycleEvent {
      final Session session;
      final Lifecycle previous;
      final Lifecycle current;
      
      public LifecycleEvent(Session session, Lifecycle previous, 
                            Lifecycle current) {
        this.session = session;
        this.previous = previous;
        this.current = current;
      }
      
      @Override
      public boolean equals(Object other) {
        if (!(other instanceof LifecycleEvent))
          return false;
        
        LifecycleEvent otherEvent = (LifecycleEvent) other;
        return session == otherEvent.session
          && previous.equals(otherEvent.previous)
          && current.equals(otherEvent.current);
      }
      
      @Override
      public String toString() {
        return session + " : " + previous + " -> " + current;
      }
    }
  }
  
  @Test
  public void testOperationGroup() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {

      AtomicInteger opCounter = new AtomicInteger();
      se.rowCountOperation("INSERT INTO " + OP_GROUP_TABLE + " VALUES (0)")
        .apply(rc -> opCounter.incrementAndGet())
        .submit();
      
      Submission<List<Boolean>> opgSubmission = null;
      try (OperationGroup<Boolean, List<Boolean>> opg = se.operationGroup()) {
        opgSubmission = 
          opg.collect(Collectors.toList())
            .timeout(getTimeout())
            .submit();
        opg.rowOperation("SELECT c FROM " + OP_GROUP_TABLE)
          .collect(Collectors.reducing(Boolean.TRUE, 
                                       row -> opCounter.compareAndSet(1, 2),
                                       (b1, b2) -> b1 && b2))
          .submit();
        opg.localOperation()
          .onExecution(() -> opCounter.compareAndSet(2, 3))
          .submit();
        opg.rowCountOperation("UPDATE " + OP_GROUP_TABLE 
                              + " SET c = 1 WHERE c = 0")
          .apply(rc -> opCounter.compareAndSet(3, 4))
          .submit();
      }
      
      assertNotNull(opgSubmission);
      List<Boolean> opgResult = 
        opgSubmission.getCompletionStage()
          .toCompletableFuture()
          .get();
      assertNotNull(opgResult);
      assertEquals(3, opgResult.size());
      for (Boolean memberResult : opgResult)
        assertTrue(memberResult);
      se.rollback()
        .toCompletableFuture()
        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    }
  }
  
  @Test
  public void testIllegalFromMemberCreatedState() {
    try (DataSource ds = getDataSource(); Session se = ds.builder().build()) {
      
      // Call APIs which are illegal after creating an operation.
      @SuppressWarnings("unused")
      Operation<Void> attachOp = se.attachOperation();
      try {
        se.conditional(CompletableFuture.completedStage(false));
        fail("IllegalStateException not thrown after creating an operation.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
      try {
        se.independent();
        fail("IllegalStateException not thrown after creating an operation.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
      try {
        se.parallel();
        fail("IllegalStateException not thrown after creating an operation.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
    }
  }
  
  @Test
  public void testIllegalFromSubmittedState() {
    try (DataSource ds = getDataSource();
         Session se = ds.builder()
                        .build()) {
      
      // Call APIs which are illegal after submitting the group.
      se.submit();

      try {
        se.submit();
        fail("IllegalStateException not thrown after submitting a group.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
      try {
        se.collect(new SessionOperationGroupTest.ObjectCollector());
        fail("IllegalStateException not thrown after submitting a group.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
      try {
        se.conditional(CompletableFuture.completedStage(false));
        fail("IllegalStateException not thrown after submitting a group.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
      try {
        se.independent();
        fail("IllegalStateException not thrown after submitting a group.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
      try {
        se.parallel();
        fail("IllegalStateException not thrown after submitting a group.");
      }
      catch (IllegalStateException expected) { /*expected*/ }
    }
  }

  @Test
  public void testIllegalFromClosedState() {
    DataSource ds = getDataSource();
    Session se = ds.builder().build();
    se.abort();
    
    // The session is now aborting or closed.
    try {
      se.arrayRowCountOperation("INSERT INTO t VALUES(?)");
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.attach();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.attach(e -> fail("Expected IllegalStateException."));
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.attachOperation();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.catchErrors();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.catchOperation();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.closeOperation();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.collect(new SessionOperationGroupTest.ObjectCollector());
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.commitMaybeRollback(new TransactionCompletion() {
        @Override
        public boolean setRollbackOnly() { return false; }
        @Override
        public boolean isRollbackOnly() { return false; }
      });
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.conditional(CompletableFuture.completedFuture(false));
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.endTransactionOperation(new TransactionCompletion() {
        @Override
        public boolean setRollbackOnly() { return false; }
        @Override
        public boolean isRollbackOnly() { return false; }
      });
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.getProperties();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.independent();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.localOperation();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.multiOperation("{CALL procedure()}");
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.operation("CREATE TABLE t");
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.operationGroup();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.outOperation("{CALL procedure()}");
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.parallel();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.registerLifecycleListener(new TestLifecycleListener());
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.requestHook(req -> fail("IllegalStateException expected."));
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.rollback();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.rowCountOperation("INSERT INTO t VALUES(1)");
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.rowOperation("SELECT * FROM t");
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.rowPublisherOperation("SELECT * FROM t");
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.shardingKeyBuilder();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.submit();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.transactionCompletion();
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.validate(Validation.COMPLETE, getTimeout(), 
                  e -> fail("IllegalStateException expected."));
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
    try {
      se.validationOperation(Validation.COMPLETE);
      fail("IllegalStateException not thrown after closing a session.");
    }
    catch (IllegalStateException expected) { /*expected*/ }
  }
  
}
