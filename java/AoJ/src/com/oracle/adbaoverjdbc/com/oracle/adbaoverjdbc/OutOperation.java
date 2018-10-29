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

import static com.oracle.adbaoverjdbc.Operation.toSQLType;
import java.sql.CallableStatement;
import java.sql.SQLException;
import java.time.Duration;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Executor;
import java.util.function.Consumer;
import java.util.function.Function;
import java.util.logging.Level;
import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.Result;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;

/**
 *
 * @param <T>
 */
public class OutOperation<T> extends ParameterizedOperation<T> 
        implements jdk.incubator.sql2.OutOperation<T> {
    
    /**
     * Factory method to create OutOperations.
     *
     * @param <S> the type of the value of the OutOperation
     * @param session the Session the OutOperation belongs to
     * @param grp the GroupOperation the OutOperation is a member of
     * @param sql the SQL string to execute.
     * @return a new OutOperation that will execute sql.
     */
    static <S> OutOperation<S> newOutOperation(Session session, OperationGroup grp, String sql) {
        return new OutOperation<>(session, grp, sql);
    }
    
    // attributes
    private final String sqlString;
    private final Map<String, SqlType> outParameters = new HashMap<>();
    protected Function<Result.OutColumn, ? extends T> processor = null;
    private CallableStatement jdbcCallableStmt;
    
    OutOperation(Session session, OperationGroup operationGroup, String sql) {
        super(session, operationGroup);
        sqlString = sql;
    }

    @Override
    public OutOperation<T> outParameter(String id, SqlType type) {
        if (isImmutable() || outParameters.containsKey(id)) {
            throw new IllegalStateException("TODO");
        }
        outParameters.put(id, type);
        return this;
    }

    @Override
    public OutOperation<T> apply(Function<Result.OutColumn, ? extends T> processor) {
        this.processor = processor;
        return this;
    }

    @Override
    public OutOperation<T> onError(Consumer<Throwable> handler) {
        return (OutOperation<T>)super.onError(handler);
    }

    @Override
    public OutOperation<T> set(String id, Object value) {
        return (OutOperation<T>)super.set(id, value);
    }

    @Override
    public OutOperation<T> set(String id, Object value, SqlType type) {
        return (OutOperation<T>)super.set(id, value, type);
    }

    @Override
    public OutOperation<T> set(String id, CompletionStage<?> source) {
        return (OutOperation<T>)super.set(id, source);
    }

    @Override
    public OutOperation<T> set(String id, CompletionStage<?> source, SqlType type) {
        return (OutOperation<T>)super.set(id, source, type);
    }

    @Override
    public OutOperation<T> timeout(Duration minTime) {
        return (OutOperation<T>)super.timeout(minTime);
    }

    @Override
    CompletionStage<T> follows(CompletionStage<?> predecessor, Executor executor) {
        predecessor = attachFutureParameters(predecessor);
        return predecessor
                .thenApplyAsync(this::execute, executor);
    }
    
    CallableStatement jdbcCallableStmt() {
        return jdbcCallableStmt;
    }
    
    String sqlString() {
        return sqlString;
    }
    
    /**
     * Executes the CallableStatement.
     * @param ignore not used
     * @return 
     */
    private T execute(Object ignore) {
        checkCanceled();
        try {
            jdbcCallableStmt = session.prepareCall(sqlString);
            
            registerOutParameters();
            bindParameters();
            
            group.logger.log(Level.FINE, () -> "execute(\"" + sqlString + "\")");
            jdbcCallableStmt.execute();
            return processor.apply(com.oracle.adbaoverjdbc.Result.newOutColumn(this));
        } 
        catch (SQLException ex) {
            throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), sqlString, -1);
        }
    }
    
    /**
     * Registers the out parameters in ordinal position id to the JDBC type
     * sqlType.
     *
     * @throws SQLException 
     */
    private void registerOutParameters() throws SQLException {
        for (Map.Entry<String, SqlType> entry : outParameters.entrySet()) {
            int id = Integer.parseInt(entry.getKey());
            SqlType type = entry.getValue();
            jdbcCallableStmt.registerOutParameter(id, toSQLType((AdbaType) type));
        }
    }
    
    /**
     * Registers the out parameters in ordinal position id to the JDBC type
     * sqlType. call from MultiOperation.
     *
     * @param jdbcCallableStmt
     * @throws SQLException 
     */
    protected void registerOutParameters(CallableStatement jdbcCallableStmt) throws SQLException {
      this.jdbcCallableStmt = jdbcCallableStmt;
      registerOutParameters();
    }
    
    
    /**
     * Sets the designated parameters to the given values.
     */
    private void bindParameters() {
        for(Map.Entry<String, ParameterValue> entry: setParameters.entrySet()) {
            ParameterValue param = entry.getValue();
            param.set(jdbcCallableStmt, entry.getKey());
        }
    }
    
}
