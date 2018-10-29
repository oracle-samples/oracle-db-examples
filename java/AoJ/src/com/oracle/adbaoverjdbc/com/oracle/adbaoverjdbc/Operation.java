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

import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.Session.Lifecycle;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlSkippedException;
import jdk.incubator.sql2.SqlType;
import jdk.incubator.sql2.Submission;
import java.math.BigInteger;
import java.sql.JDBCType;
import java.sql.SQLType;
import java.time.Duration;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.OffsetDateTime;
import java.time.OffsetTime;
import java.util.HashMap;
import java.util.Map;
import java.util.Map.Entry;
import java.util.concurrent.CompletionException;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.function.Consumer;

/**
 * An Operation collects the various properties of the request for work, then
 * constructs one or more CompletionStages that will do the work of the
 * Operation. Finally it connects the CompletionStage(s) to result
 * CompletionStage of the preceeding Operation.
 *
 */
abstract class Operation<T> implements jdk.incubator.sql2.Operation<T> {
  
  private static final Map<Class, SQLType> CLASS_TO_JDBCTYPE = new HashMap<>(20);
  static {
    try {
      CLASS_TO_JDBCTYPE.put(BigInteger.class, JDBCType.BIGINT);
      CLASS_TO_JDBCTYPE.put(Boolean.class, JDBCType.BOOLEAN);
      CLASS_TO_JDBCTYPE.put(Byte.class, JDBCType.TINYINT);
      CLASS_TO_JDBCTYPE.put(Class.forName("[B"), JDBCType.VARBINARY);
      CLASS_TO_JDBCTYPE.put(Character.class, JDBCType.CHAR);
      CLASS_TO_JDBCTYPE.put(Double.class, JDBCType.DOUBLE);
      CLASS_TO_JDBCTYPE.put(Float.class, JDBCType.FLOAT);
      CLASS_TO_JDBCTYPE.put(Integer.class, JDBCType.INTEGER);
      CLASS_TO_JDBCTYPE.put(LocalDate.class, JDBCType.DATE);
      CLASS_TO_JDBCTYPE.put(LocalDateTime.class, JDBCType.TIMESTAMP);
      CLASS_TO_JDBCTYPE.put(LocalTime.class, JDBCType.TIME);
      CLASS_TO_JDBCTYPE.put(OffsetDateTime.class, JDBCType.TIMESTAMP_WITH_TIMEZONE);
      CLASS_TO_JDBCTYPE.put(OffsetTime.class, JDBCType.TIME_WITH_TIMEZONE);
      CLASS_TO_JDBCTYPE.put(Short.class, JDBCType.SMALLINT);
      CLASS_TO_JDBCTYPE.put(String.class, JDBCType.VARCHAR);
    }
    catch (ClassNotFoundException ex) { /* should never happen */ }
  }
  
  private static final Map<SqlType, SQLType> ADBATYPE_TO_JDBCTYPE = new HashMap<>(40);
  static {
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.ARRAY, JDBCType.ARRAY);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.BIGINT, JDBCType.BIGINT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.BINARY, JDBCType.BINARY);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.BIT, JDBCType.BIT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.BOOLEAN, JDBCType.BOOLEAN);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.CHAR, JDBCType.CHAR);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.CLOB, JDBCType.CLOB);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.DATALINK, JDBCType.DATALINK);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.DATE, JDBCType.DATE);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.DECIMAL, JDBCType.DECIMAL);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.DISTINCT, JDBCType.DISTINCT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.DOUBLE, JDBCType.DOUBLE);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.FLOAT, JDBCType.FLOAT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.INTEGER, JDBCType.INTEGER);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.JAVA_OBJECT, JDBCType.JAVA_OBJECT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.LONG_NVARCHAR, JDBCType.LONGNVARCHAR);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.LONG_VARBINARY, JDBCType.LONGVARBINARY);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.LONG_VARCHAR, JDBCType.LONGVARBINARY);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.NCHAR, JDBCType.NCHAR);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.NCLOB, JDBCType.NCLOB);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.NULL, JDBCType.NULL);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.NUMERIC, JDBCType.NUMERIC);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.NVARCHAR, JDBCType.NVARCHAR);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.OTHER, JDBCType.OTHER);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.REAL, JDBCType.REAL);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.REF, JDBCType.REF);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.REF_CURSOR, JDBCType.REF_CURSOR);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.ROWID, JDBCType.ROWID);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.SMALLINT, JDBCType.SMALLINT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.SQLXML, JDBCType.SQLXML);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.STRUCT, JDBCType.STRUCT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.TIME, JDBCType.TIME);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.TIMESTAMP, JDBCType.TIMESTAMP);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.TIME_WITH_TIME_ZONE, JDBCType.TIME_WITH_TIMEZONE);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.TIMESTAMP_WITH_TIME_ZONE, JDBCType.TIMESTAMP_WITH_TIMEZONE);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.TINYINT, JDBCType.TINYINT);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.VARBINARY, JDBCType.VARBINARY);
    ADBATYPE_TO_JDBCTYPE.put(AdbaType.VARCHAR, JDBCType.VARCHAR);
  }
  
  /**
   * Find the default SQLType to represent a Java type.
   * 
   * @param c a Java type
   * @return the default SQLType to represent the Java type
   */
  static SQLType toSQLType(Class c) {
    SQLType s = CLASS_TO_JDBCTYPE.get(c);
    if (s == null) {
      throw new UnsupportedOperationException("Not supported yet.");
    }
    return s;
  }

  /**
   * Return the java.sql.SQLType corresponding to the jdk.incubator.sql2.SqlType.
   * 
   * @param t an ADBA type
   * @return a JDBC type
   */
  static SQLType toSQLType(SqlType t) {
    SQLType s = ADBATYPE_TO_JDBCTYPE.get(t);
    if (s == null) {
      throw new UnsupportedOperationException("Not supported yet.");      
    }
    return s;
  }

  /**
   * Return the jdk.incubator.sql2.SqlType corresponding to the 
   * java.sql.SQLType.
   * 
   * @param t a JDBC type
   * @return an ADBA type
   */
  static SqlType fromSQLType(SQLType t) {
    for (Entry<SqlType, SQLType> mapping : ADBATYPE_TO_JDBCTYPE.entrySet()) {
      if (mapping.getValue() == t)
        return mapping.getKey();
    }
    throw new RuntimeException(
      "No SqlType mapping is defined for SQLType: " + t);
  }
  
  static Throwable unwrapException(Throwable ex) {
    return ex instanceof CompletionException ? ex.getCause() : ex;
  }
  
  // attributes
  protected Duration timeout = null;
  protected Consumer<Throwable> errorHandler = null;
  
  // internal state
  protected final Session session;
  protected final OperationGroup<T, ?> group;
  protected OperationLifecycle operationLifecycle = OperationLifecycle.MUTABLE;
  
  // used only by Session
  protected Operation() {
    session = (Session)this;
    group = (OperationGroup)this;
  }

  Operation(Session session, OperationGroup operationGroup) {
    this.session = session;
    group = operationGroup;
  }

  @Override
  public Operation<T> onError(Consumer<Throwable> handler) {
    if (isImmutable() || errorHandler != null) {
      throw new IllegalStateException("TODO");
    }
    if (handler == null) {
      throw new IllegalArgumentException("TODO");
    }
    errorHandler = handler;
    return this;
  }

  @Override
  public Operation<T> timeout(Duration minTime) {
    if (isImmutable() || timeout != null) {
      throw new IllegalStateException("TODO");
    }
    if (minTime == null || minTime.isNegative() || minTime.isZero()) {
      throw new IllegalArgumentException("TODO");
    }
    timeout = minTime;
    return this;
  }

  @Override
  public Submission<T> submit() {
    if (isImmutable()) {
      throw new IllegalStateException("TODO");
    }
    immutable();
    return group.submit(this);
  }

  /**
   * Returns true if this Operation is immutable. An Operation is immutable if
   * it has been submitted. Held OperationGroups are an exception.
   * 
   * @return return true if immutable
   */
  boolean isImmutable() {
    return operationLifecycle.isImmutable();
  }

  protected Operation<T> immutable() {
    operationLifecycle = OperationLifecycle.RELEASED;
    return this;
  }

  long getTimeoutMillis() {
    if (timeout == null) {
      return 0L;
    }
    else {
      return timeout.toMillis();
    }
  }
  
  protected Executor getExecutor() {
    return session.getExecutor();
  }

  /**
   * Attaches the CompletableFuture that starts this Operation to the tail and
   * return a CompletableFuture that represents completion of this Operation.
   * The returned CompletableFuture may not be directly attached to the tail,
   * but completion of the tail should result in completion of the returned
   * CompletableFuture. (Note: Not quite true for OperationGroups. While the 
   * returned CompletableFuture does depend on the tail, it also depends on 
   * user code calling {@link OperationGroup#close()}.)
   *
   * @param tail the predecessor of this operation. Completion of tail starts
   * execution of this Operation
   * @param executor used for asynchronous execution
   * @return completion of this CompletableFuture means this Operation is
   * complete. The value of the Operation is the value of the CompletableFuture.
   */
  abstract CompletionStage<T> follows(CompletionStage<?> tail, Executor executor);

  boolean cancel() {
    if (operationLifecycle.isFinished()) {
      return false;
    }
    else {
      operationLifecycle = OperationLifecycle.CANCELED;
      return true;
    }
  }

  boolean isCanceled() {
    return operationLifecycle.isCanceled();
  }
  
  Operation<T> checkCanceled() {
    if (isCanceled()) {
      throw new SqlSkippedException("TODO", null, null, -1, null, -1);
    }
    return this;
  }

  /**
   * Attaches a completion stage which handles completion of the stage returned
   * by {@link Operation#follows(CompletionStage, Executor)}.
   * <br>
   * If the session is aborted, the attached stage will complete exceptionally 
   * with a RuntimeException, with any exceptional completion from the 
   * argument added as a suppressed exception. Neither 
   * {@link Operation#handleResult(Object)} nor 
   * {@link Operation#handleError(Throwable)} will be called.
   * <br>
   * If the argument completes normally, it's computed value is passed to 
   * {@link Operation#handleResult(Object)}, and the returned value completes 
   * the the stage returned by this method. 
   * <br>
   * Otherwise, if the argument completes exceptionally, the 
   * CompletetionException's cause is passed to 
   * {@link Operation#handleError(Throwable)}, and the returned Throwable 
   * exceptionally completes the stage returned by this method.  
   * 
   * @param result A CompletionStage returned by 
   *   {@link Operation#follows(CompletionStage, Executor)}.
   * @return a CompletionStage that will handle the argument's completion.
   */
  final CompletionStage<T> attachCompletionHandler(CompletionStage<T> result) {
    return result.handle((r, t) -> {
      Throwable ex = unwrapException(t);
      checkAbort(ex);
      
      if (t == null)
        return handleResult(r);
      else
        throw handleError(ex);
    });
  }

  /**
   * Check if the session has been aborted.
   * @param suppressed A Throwable to be added as a suppressed exception if 
   *   this method throws a RuntimeException. Maybe null, in which case no 
   *   suppressed exception will be added.
   * @throws RuntimeException If the session is aborted.
   */
  private void checkAbort(Throwable suppressed) {
    if (Lifecycle.ABORTING == session.getSessionLifecycle()) {
      RuntimeException abortEx = new RuntimeException("Session aborted.");
      if (suppressed != null) abortEx.addSuppressed(suppressed);
      throw abortEx;
    }
  }
  
  /**
   * Handle the result of this operation.
   * <br>
   * The {@code result} argument is the value computed by the 
   * {@link Operation#follows(CompletionStage, Executor)} stage. This method
   * is only called when the stage completes normally.
   *  
   * @implSpec Operation's implementation of this method will pass the 
   * {@code result} argument to the
   * {@link OperationGroup#accumulateResult(Object)} method of this 
   * operation's group.  
   * @param result The result of the 
   * {@link Operation#follows(CompletionStage, Executor)} stage.
   * @return The result of this operation.
   */
  protected T handleResult(T result) {
    group.accumulateResult(result);
    return result;
  }
  
  /**
   * Handle exceptional completion of this operation. The {@code ex} argument
   * is the result of the {@link Operation#follows(CompletionStage, Executor)}
   * stage. This method is only called when the stage completes exceptionally. 
   * Assuming the stage completed exceptionally with a 
   * {@link CompletionException}, the {@code ex} argument is the return value
   * of {@link CompletionException#getCause()}.
   *  
   * @implSpec Operation's implementation of this method will invoke any 
   *   handler defined by {@link Operation#onError(Consumer)}. If 
   *   the {@code ex} argument is not a SqlSkippedException, this 
   *   implementation returns a SqlSkippedException with {@code ex} as it's 
   *   cause. Otherwise, {@code ex} is returned as is.
   * @param ex An exception which completed this operation. Not null.
   * @return A SqlSkippedException which describes the provided exception, 
   *   {@code ex}, as the cause for a skipping subsequent member operations.
   */
  protected SqlSkippedException handleError(Throwable ex) {
    if (ex instanceof SqlSkippedException) 
      throw (SqlSkippedException)ex;
    else {
      // Only called if execution of *this* operation results in an error.
      if (errorHandler != null) errorHandler.accept(ex);
      
      if (ex instanceof SqlException)
        throw new SqlSkippedException((SqlException)ex);
      else 
        throw new SqlSkippedException(/*(Throwable)*/ex);
    }
  }
  
  static enum OperationLifecycle {
    MUTABLE,
    HELD,
    RELEASED,
    COMPLETED,
    CANCELED;
    
    /**
     * @return true iff op has been submitted which means no more configuration
     */
    boolean isSubmitted() {
      return this != MUTABLE;
    }
        
    /**
     * @return return true if no new members may be added. Implies isSubmitted
     */
    boolean isImmutable() { //TODO better name?
      return this == RELEASED || this == COMPLETED || this == CANCELED;
    }
    
    boolean isFinished() {
      return this == COMPLETED || this == CANCELED;
    }
    
    boolean isCanceled() {
      return this == CANCELED;
    }
    
  }
}
