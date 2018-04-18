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

import jdk.incubator.sql2.AdbaConnectionProperty;
import jdk.incubator.sql2.Connection.Lifecycle;
import jdk.incubator.sql2.ConnectionProperty;
import jdk.incubator.sql2.Operation;
import jdk.incubator.sql2.ShardingKey;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.TransactionOutcome;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Properties;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;

/**
 * Connection is a subclass of OperationGroup. The member Operation stuff is mostly
 * inherited from OperationGroup. There are a couple of differences. First the
 * predecessor for all Connections is an already completed CompletableFuture, 
 * ROOT. Since ROOT is completed a Connection will begin executing as soon as it
 * is submitted. Second, a Connection is not really a member of an OperationGroup
 * so the code that handles submitting the Connection is a little different from
 * OperationGroup.
 * 
 * A Connection is also contains a java.sql.Connection and has methods to execute
 * some JDBC actions. It might be a good idea to move the java.sql.Connection and
 * associated actions to a separate class.
 */
class Connection extends OperationGroup<Object, Object> implements jdk.incubator.sql2.Connection {

  // STATIC
  protected static final CompletionStage<Object> ROOT = CompletableFuture.completedFuture(null);

  static jdk.incubator.sql2.Connection newConnection(DataSource ds,
                                                  Map<ConnectionProperty, Object> properties) {
    return new Connection(ds, properties);
  }

  // FIELDS
  private Lifecycle connectionLifecycle = Lifecycle.NEW;
  private final Set<jdk.incubator.sql2.Connection.ConnectionLifecycleListener> lifecycleListeners;
  private final DataSource dataSource;
  private final Map<ConnectionProperty, Object> properties;

  private java.sql.Connection jdbcConnection;

  private final Executor executor;
  private CompletableFuture<Object> connectionCF;

  // CONSTRUCTORS
  private Connection(DataSource ds,
                     Map<ConnectionProperty, Object> properties) {
    super(null, null); // hack as _this_ not allowed. See SimpleOperation constructor
    this.lifecycleListeners = new HashSet<>();
    dataSource = ds;
    this.properties = properties;
    ConnectionProperty execProp = AdbaConnectionProperty.EXECUTOR;
    executor = (Executor) properties.getOrDefault(execProp, execProp.defaultValue());
  }

  // PUBLIC
  @Override
  public Operation<Void> connectOperation() {
    if (! isHeld()) {
      throw new IllegalStateException("TODO");
    }
    return com.oracle.adbaoverjdbc.SimpleOperation.<Void>newOperation(this, this, this::jdbcConnect);
  }

  @Override
  public Operation<Void> validationOperation(Validation depth) {
    if (! isHeld()) {
      throw new IllegalStateException("TODO");
    }
    return com.oracle.adbaoverjdbc.SimpleOperation.<Void>newOperation(this, this, op -> jdbcValidate(op, depth));
  }

  @Override
  public Operation<Void> closeOperation() {
    if (! isHeld()) {
      throw new IllegalStateException("TODO");
    }
    return com.oracle.adbaoverjdbc.UnskippableOperation.<Void>newOperation(this, this, this::jdbcClose);  //TODO cannot be skipped
  }

  @Override
  public <S, T> jdk.incubator.sql2.OperationGroup<S, T> operationGroup() {
    if (!isHeld()) {
      throw new IllegalStateException("TODO");
    }
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public Transaction transaction() {
    if (! isHeld()) {
      throw new IllegalStateException("TODO");
    }
    return Transaction.createTransaction(this);
  }

  @Override
  public Connection registerLifecycleListener(ConnectionLifecycleListener listener) {
    if (!connectionLifecycle.isActive()) {
      throw new IllegalStateException("TODO");
    }
    lifecycleListeners.add(listener);
    return this;
  }

  @Override
  public Connection deregisterLifecycleListener(ConnectionLifecycleListener listener) {
    if (!connectionLifecycle.isActive()) {
      throw new IllegalStateException("TODO");
    }
    lifecycleListeners.remove(listener);
    return this;
  }

  @Override
  public Lifecycle getConnectionLifecycle() {
    return connectionLifecycle;
  }

  @Override
  public jdk.incubator.sql2.Connection abort() {
    setLifecycle(connectionLifecycle.abort());
    this.closeImmediate();
    return this;
  }

  @Override
  public Map<ConnectionProperty, Object> getProperties() {
    Map<ConnectionProperty, Object> map = new HashMap<>(properties.size());
    properties.forEach((k, v) -> {
      if (!k.isSensitive()) {
        map.put(k, v);
      }
    });
    return map;
  }

  @Override
  public ShardingKey.Builder shardingKeyBuilder() {
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public jdk.incubator.sql2.Connection activate() {
    setLifecycle(connectionLifecycle.activate());
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public jdk.incubator.sql2.Connection deactivate() {
    setLifecycle(connectionLifecycle.deactivate());
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }
  
  
  
  
  // INTERNAL
  protected Connection setLifecycle(Lifecycle next) {
    Lifecycle previous = connectionLifecycle;
    connectionLifecycle = next;
    if (previous != next) {
      lifecycleListeners.stream().forEach(l -> l.lifecycleEvent(this, previous, next));
    }
    return this;
  }

  Connection closeImmediate() {
    try {
      if (jdbcConnection != null && !jdbcConnection.isClosed()) {
        setLifecycle(connectionLifecycle.abort());
        jdbcConnection.abort(executor);  // Connection.abort is not supposed to hang
        //TODO should call connectionLifecycle.close() when abort completes.
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
    finally {
      dataSource.deregisterConnection(this);
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
      // submitting the Connection OperationGroup
      connectionCF = (CompletableFuture<Object>)attachErrorHandler(op.follows(ROOT, getExecutor()));
      return com.oracle.adbaoverjdbc.Submission.submit(this::cancel, connectionCF);
    }
    else {
      return super.submit(op);
    }
  }
  
  

  
  // JDBC operations. These are all blocking
  
  private Void jdbcConnect(com.oracle.adbaoverjdbc.Operation<Void> op) {
    try {
    Properties info = (Properties) ((Properties) properties.get(JdbcConnectionProperties.JDBC_CONNECTION_PROPERTIES)).clone();
    info.setProperty("user", (String) properties.get(AdbaConnectionProperty.USER));
    info.setProperty("password", (String) properties.get(AdbaConnectionProperty.PASSWORD));
    String url = (String) properties.get(AdbaConnectionProperty.URL);
    System.out.println("DriverManager.getConnection(\"" + url + "\", " + info +")"); //DEBUG
    jdbcConnection = DriverManager.getConnection(url, info);
    jdbcConnection.setAutoCommit(false);
    setLifecycle(Connection.Lifecycle.OPEN);
    return null;
    }
    catch (SQLException ex) {
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
        System.out.println("Connection.isValid(" + timeoutSeconds + ")"); //DEBUG
        if (!jdbcConnection.isValid(timeoutSeconds)) {
          throw new SqlException("validation failure", null, null, -1, null, -1);
        }
        break;
      case NETWORK:
      case SOCKET:
      case LOCAL:
      case NONE:
        System.out.println("Connection.isClosed"); //DEBUG
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
      System.out.println("Statement.execute(\"" + sql + "\")"); //DEBUG
      stmt.execute(sql);
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sql, -1);
    }
    return null;
  }

  private Void jdbcClose(com.oracle.adbaoverjdbc.Operation<Void> op) {
    try {
      setLifecycle(connectionLifecycle.close());
      if (jdbcConnection != null) {
        System.out.println("Connection.close"); //DEBUG
        jdbcConnection.close();
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
    finally {
      closeImmediate();
      setLifecycle(connectionLifecycle.closed());
    }
    return null;
  }

  PreparedStatement prepareStatement(String sqlString) throws SQLException {
    System.out.println("Connection.prepareStatement(\"" + sqlString + "\")"); //DEBUG
    return jdbcConnection.prepareStatement(sqlString);
  }

  TransactionOutcome jdbcEndTransaction(SimpleOperation<TransactionOutcome> op, Transaction trans) {
    try {
      if (trans.endWithCommit(this)) {
        System.out.println("commit"); //DEBUG
        jdbcConnection.commit();
        return TransactionOutcome.COMMIT;
      }
      else {
        System.out.println("rollback"); //DEBUG
        jdbcConnection.rollback();
        return TransactionOutcome.ROLLBACK;
      }
    }
    catch (SQLException ex) {
      throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
    }
  }
  
}
