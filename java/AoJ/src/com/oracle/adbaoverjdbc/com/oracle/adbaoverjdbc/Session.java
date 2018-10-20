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
import jdk.incubator.sql2.AdbaSessionProperty;
import jdk.incubator.sql2.SessionProperty;
import jdk.incubator.sql2.Operation;
import jdk.incubator.sql2.ShardingKey;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.TransactionOutcome;

import java.sql.CallableStatement;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.CopyOnWriteArraySet;
import java.util.concurrent.Executor;
import java.util.function.LongConsumer;
import java.util.logging.Level;

/**
 * Session is a subclass of OperationGroup. The member Operation stuff is mostly
 * inherited from OperationGroup. There are a couple of differences. First the
 * predecessor for all Sessions is an already completed CompletableFuture, 
 * ROOT. Since ROOT is completed a Session will begin executing as soon as it
 * is submitted. Second, a Session is not really a member of an OperationGroup
 * so the code that handles submitting the Session is a little different from
 * OperationGroup.
 * 
 * A Session is also contains a java.sql.Session and has methods to execute
 * some JDBC actions. It might be a good idea to move the java.sql.Session and
 * associated actions to a separate class.
 */
class Session extends OperationGroup<Object, Object> implements jdk.incubator.sql2.Session {

  // STATIC
  protected static final CompletionStage<Object> ROOT = CompletableFuture.completedFuture(null);

  static jdk.incubator.sql2.Session newSession(DataSource ds,
                                                  Map<SessionProperty, Object> properties) {
    return new Session(ds, properties);
  }

  // FIELDS
  private Lifecycle sessionLifecycle = Lifecycle.NEW;
  private final Set<jdk.incubator.sql2.Session.SessionLifecycleListener> lifecycleListeners;
  private final DataSource dataSource;
  private final Map<SessionProperty, Object> properties;

  private java.sql.Connection jdbcConnection;

  private final Executor executor;
  private CompletableFuture<Object> sessionCF;

  // CONSTRUCTORS
  private Session(DataSource ds,
                     Map<SessionProperty, Object> properties) {
    super();
    this.lifecycleListeners = new CopyOnWriteArraySet<>();
    dataSource = ds;
    this.properties = properties;
    SessionProperty execProp = AdbaSessionProperty.EXECUTOR;
    executor = (Executor) properties.getOrDefault(execProp, execProp.defaultValue());
  }

  // PUBLIC
  @Override
  public Operation<Void> attachOperation() {
    assertOpen();
    if (sessionLifecycle != Lifecycle.NEW) {
      throw new IllegalStateException(
        "Session lifecycle is: " + getSessionLifecycle());
    }
    return addMember(
      com.oracle.adbaoverjdbc.SimpleOperation.<Void>newOperation(
        this, this, this::jdbcConnect));
  }

  @Override
  public Operation<Void> validationOperation(Validation depth) {
    assertOpen();
    return addMember(
      com.oracle.adbaoverjdbc.SimpleOperation.<Void>newOperation(
        this, this, op -> jdbcValidate(op, depth)));
  }

  @Override
  public Operation<Void> closeOperation() {
    assertOpen();
    return addMember(
      com.oracle.adbaoverjdbc.UnskippableOperation.<Void>newOperation(
        this, this, this::jdbcClose));  //TODO cannot be skipped
  }

  @Override
  public <S, T> jdk.incubator.sql2.OperationGroup<S, T> operationGroup() {
    assertOpen();
    return addMember(OperationGroup.newOperationGroup(this));
  }

  @Override
  public TransactionCompletion transactionCompletion() {
    assertOpen();
    return TransactionCompletion.createTransaction(this);
  }

  @Override
  public Session registerLifecycleListener(SessionLifecycleListener listener) {
    assertOpen();
    lifecycleListeners.add(listener);
    return this;
  }

  @Override
  public Session deregisterLifecycleListener(SessionLifecycleListener listener) {
    lifecycleListeners.remove(listener);
    return this;
  }

  @Override
  public Lifecycle getSessionLifecycle() {
    return sessionLifecycle;
  }

  @Override
  public jdk.incubator.sql2.Session abort() {
    if (sessionLifecycle == Lifecycle.ABORTING 
       || sessionLifecycle == Lifecycle.CLOSED) { 
      return this;
    }
    setLifecycle(sessionLifecycle.abort());
    this.closeImmediate();

    if (operationLifecycle.isSubmitted())
      sessionCF.whenComplete((v, e) -> setLifecycle(Lifecycle.CLOSED));
    else
      setLifecycle(sessionLifecycle.closed());
    
    if (!isImmutable()) super.close();
    
    return this;
  }

  @Override
  public Map<SessionProperty, Object> getProperties() {
    assertOpen();
    Map<SessionProperty, Object> map = new HashMap<>(properties.size());
    properties.forEach((k, v) -> {
      if (!k.isSensitive()) {
        if (v instanceof Cloneable) {
          v = DataSourceBuilder.tryClone((Cloneable)v);
        }
        map.put(k, v);
      }
    });
    return map;
  }

  @Override
  public ShardingKey.Builder shardingKeyBuilder() {
    assertOpen();
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public jdk.incubator.sql2.Session requestHook(LongConsumer request) {
    assertOpen();
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }
  
  @Override
  public void close() {
    closeOperation().submit();
    super.close();
  }
  
  // INTERNAL
  protected Session setLifecycle(Lifecycle next) {
    Lifecycle previous = sessionLifecycle;
    sessionLifecycle = next;
    if (previous != next) {
      lifecycleListeners.stream().forEach(l -> l.lifecycleEvent(this, previous, next));
    }
    return this;
  }

  Session closeImmediate() {
    try {
      if (jdbcConnection != null) {
        jdbcConnection.abort(executor);  // Session.abort is not supposed to hang
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
    finally {
      dataSource.deregisterSession(this);
    }
    return this;
  }

  @Override
  protected Executor getExecutor() {
    return executor;
  }

  @Override
  jdk.incubator.sql2.Submission<Object> submit(com.oracle.adbaoverjdbc.Operation<Object> op) {
    if (op == this) {
      // submitting the Session OperationGroup
      sessionCF = (CompletableFuture<Object>)attachCompletionHandler(op.follows(ROOT, getExecutor()));
      return com.oracle.adbaoverjdbc.Submission.submit(this::cancel, sessionCF);
    }
    else {
      return super.submit(op);
    }
  }
  
  @SuppressWarnings("unchecked")
  protected <V> V sessionPropertyValue(SessionProperty prop) {
    V value = (V)properties.get(prop);
    if (value == null) return (V)prop.defaultValue();
    else return value;
  }
  
  

  
  // JDBC operations. These are all blocking
  
  private Void jdbcConnect(com.oracle.adbaoverjdbc.Operation<Void> op) {
    try {
      Properties info = (Properties)properties.get(JdbcConnectionProperties.JDBC_CONNECTION_PROPERTIES);
      info = (Properties)(info == null ? JdbcConnectionProperties.JDBC_CONNECTION_PROPERTIES.defaultValue() 
                                       : info.clone());
      
      Properties sensitiveInfo = (Properties)properties.get(
        JdbcConnectionProperties.SENSITIVE_JDBC_CONNECTION_PROPERTIES);
      if (sensitiveInfo != null)
        info.putAll(sensitiveInfo);
      
      String user = (String) properties.get(AdbaSessionProperty.USER);
      if (user != null)
        info.setProperty("user", user);
      
      String password = (String) properties.get(AdbaSessionProperty.PASSWORD);
      if (password != null)
        info.setProperty("password", password);
      
      String url = (String) properties.get(AdbaSessionProperty.URL);
      Properties p = info;
      group.logger.log(Level.FINE, () -> "DriverManager.getSession(\"" + url + "\", " + p +")");
      jdbcConnection = DriverManager.getConnection(url, info);
      jdbcConnection.setAutoCommit(false);
      
      if (sessionLifecycle == Lifecycle.ABORTING)
        closeImmediate();
      else
        setLifecycle(Session.Lifecycle.ATTACHED);
      
      return null;
    }
    catch (SQLException ex) {
      setLifecycle(Session.Lifecycle.CLOSED);
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
  }

  private Void jdbcValidate(com.oracle.adbaoverjdbc.Operation<Void> op,
                            Validation depth) {
    try {
    switch (depth) {
      case COMPLETE:
      case SERVER:
        int timeoutSeconds = (int) (op.getTimeoutMillis() / 1000L);
        group.logger.log(Level.FINE, () -> "Session.isValid(" + timeoutSeconds + ")"); //DEBUG
        if (!jdbcConnection.isValid(timeoutSeconds)) {
          throw new SqlException("validation failure", null, null, -1, null, -1);
        }
        break;
      case NETWORK:
      case SOCKET:
      case LOCAL:
      case NONE:
        group.logger.log(Level.FINE, () -> "Session.isClosed"); //DEBUG
        if (jdbcConnection.isClosed()) {
          throw new SqlException("validation failure", null, null, -1, null, -1);
        }
    }
    return null;
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
  }
  
  
  protected <T> T jdbcExecute(com.oracle.adbaoverjdbc.Operation<T> op, String sql) {
    try (java.sql.Statement stmt = jdbcConnection.createStatement()) {
      int timeoutSeconds = (int) (op.getTimeoutMillis() / 1000L);
      if (timeoutSeconds < 0) stmt.setQueryTimeout(timeoutSeconds);
      group.logger.log(Level.FINE, () -> "Statement.execute(\"" + sql + "\")"); //DEBUG
      stmt.execute(sql);
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sql, -1);
    }
    return null;
  }

  private Void jdbcClose(com.oracle.adbaoverjdbc.Operation<Void> op) {
    try {
      setLifecycle(sessionLifecycle.close());
      if (jdbcConnection != null) {
        group.logger.log(Level.FINE, () -> "Session.close"); //DEBUG
        jdbcConnection.close();
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
    finally {
      closeImmediate();
      setLifecycle(sessionLifecycle.closed());
    }
    return null;
  }

  PreparedStatement prepareStatement(String sqlString) throws SQLException {
    logger.log(Level.FINE, () -> "Session.prepareStatement(\"" + sqlString + "\")"); //DEBUG
    return jdbcConnection.prepareStatement(sqlString);
  }
  
  CallableStatement prepareCall(String sqlString) throws SQLException {
      logger.log(Level.FINE, () -> "Session.prepareCall(\"" + sqlString + "\")"); //DEBUG
      return jdbcConnection.prepareCall(sqlString);
  }

  PreparedStatement prepareStatement(String sqlString, String[] auotKeyColNames) throws SQLException {
    logger.log(Level.FINE, () -> "Session.prepareStatement(\"" + sqlString + "\")"); //DEBUG
    return jdbcConnection.prepareStatement(sqlString, auotKeyColNames);
  }
  
  TransactionOutcome jdbcEndTransaction(SimpleOperation<TransactionOutcome> op, TransactionCompletion trans) {
    try {
      if (trans.endWithCommit(this)) {
        group.logger.log(Level.FINE, () -> "commit"); //DEBUG
        jdbcConnection.commit();
        return TransactionOutcome.COMMIT;
      }
      else {
        group.logger.log(Level.FINE, () -> "rollback"); //DEBUG
        jdbcConnection.rollback();
        return TransactionOutcome.ROLLBACK;
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
  }

  /**
   * Override for Session, where {@link Operation}'s group field is this
   * Session; The result of this Session should not be accumulated by it's own
   * Collector. (The result of this session is the result of the Collector's
   * finisher function).
   * <br>
   * TODO: Change the argument and return value's type to a generic, rather 
   * than Object. Currently, there's no API to define the S and T types for a
   * Session. 
   */
  @Override
  protected Object handleResult(Object result) {
    return result;
  }
}
