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
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletionStage;
import static com.oracle.adbaoverjdbc.Operation.toSQLType;
import static com.oracle.adbaoverjdbc.Operation.toSQLType;

/**
 *
 */
public abstract class ParameterizedOperation<T> extends Operation<T>
        implements jdk.incubator.sql2.ParameterizedOperation<T> {
  
  protected final Map<String, ParameterValue> setParameters;
  protected CompletionStage futureParameters;

  ParameterizedOperation(Connection conn, OperationGroup operationGroup) {
    super(conn, operationGroup);
    setParameters = new HashMap<>();
  }
  
  CompletionStage attachFutureParameters(CompletionStage predecessor) {
    if (futureParameters == null) return predecessor;
    else  return predecessor.runAfterBoth(futureParameters, () -> {});
  }

  @Override
  public ParameterizedOperation<T> set(String id, Object value, SqlType type) {
    if (isImmutable() || setParameters.containsKey(id)) {
      throw new IllegalStateException("TODO");
    }
    if (id == null || (type != null && !(type instanceof AdbaType))) {
      throw new IllegalArgumentException("TODO");
    }
    if (value instanceof CompletionStage) {
      if (futureParameters == null) {
        futureParameters = ((CompletionStage)value)
                .thenAccept( v -> { setParameters.put(id, new ParameterValue(v, type)); });
      }
      else {
        futureParameters = ((CompletionStage)value)
               .thenAcceptBoth(futureParameters, 
                               (v, f) -> { setParameters.put(id, new ParameterValue(v, type)); });
      }
    }
    else {
      setParameters.put(id, new ParameterValue(value, type));
    }
    return this;
  }
  
  @Override
  public ParameterizedOperation<T> set(String id, CompletionStage<?> source, SqlType type) {
    return set(id, (Object) source, type);
  }

  @Override
  public ParameterizedOperation<T> set(String id, CompletionStage<?> source) {
    return set(id, (Object) source, null);
  }

  @Override
  public ParameterizedOperation<T> set(String id, Object value) {
    return set(id, value, null);
  }
  
  static final class ParameterValue {
    
    final Object value;
    final SqlType type;
    
    ParameterValue(Object val, SqlType typ) {
      value = val;
      type = typ;
    }
    
    void set(PreparedStatement stmt, String id) {
      try {
        try {
          setByPosition(stmt, Integer.parseInt(id));
        }
        catch (NumberFormatException ex) {
          setByName(stmt, id);
        }
      }
      catch (SQLException ex) {
        throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), ex.getErrorCode(), null, -1);
      }
    }
                    
    void setByPosition(PreparedStatement stmt, int index) throws SQLException {
      if (type == null) {
        stmt.setObject(index, value, toSQLType(value.getClass()));
      }
      else if (type instanceof AdbaType) {
         stmt.setObject(index, value, toSQLType((AdbaType)type));
      }
      else {
        throw new IllegalArgumentException("TODO");
      }
    }
    
    void setByName(PreparedStatement stmt, String id) throws SQLException {
      throw new UnsupportedOperationException("Not supported yet.");
    }
  }
  
  
}
