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

import java.sql.JDBCType;
import java.sql.SQLException;
import java.util.NoSuchElementException;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.SqlType;

/**
 * Result of the given database operation.
 */

abstract class Result {
    
    static jdk.incubator.sql2.Result.RowCount newRowCount(long c) {
        return new Result.RowCount(c);
    }
    
    static Result.RowColumn newRowColumn(RowBaseOperation op) {
        return new Result.RowColumn(op);
    }
    
    static jdk.incubator.sql2.Result.OutColumn newOutColumn(OutOperation op) {
      try {
        return new Result.OutColumn(op, 
                                    op.jdbcCallableStmt()
                                      .getParameterMetaData()
                                      .getParameterCount());
      }
      catch (SQLException ex) {
        throw new SqlException(ex.getMessage(), ex, ex.getSQLState(),
                               ex.getErrorCode(), op.sqlString(), -1);
      }
    }
            
    /**
     * Represents the result of a SQL execution that is an update count.
     *
     * ISSUE: It's not obvious this type is more valuable than just using
     * java.lang.Long. Result.Count exists to clearly express that the input arg
     * to the processor Function is a count. Could rely on documentation but
     * this seems like it might be important enough to capture in the type
     * system. There also may be non-numeric return values that Result.Count
     * could express, eg success but number unknown.
     */
    private static final class RowCount implements jdk.incubator.sql2.Result.RowCount {

        private long count = -1;

        public RowCount(long c) {
            count = c;
        }

        @Override
        public long getCount() {
            return count;
        }
    }

    /**
     * This abstract class handles column positioning and slicing the 
     * subsequence. Subclasses implement abstract methods to work with their
     * underlying JDBC objects; RowColumn works with a ResultSet, OutColumn 
     * with a CallableStatment. Abstract methods should be implemented to 
     * accept absolute column/parameter indexes. The indexes are never
     * relative to the first column in a sliced sequence. 
     */
    private static abstract class Column 
      implements jdk.incubator.sql2.Result.Column, AutoCloseable {

      private volatile boolean isClosed = false; // all slices and clones share this
      private int columnIndex = -1;
      private int columnOffset = 0; // used by slices
      private int lastColumn = Integer.MAX_VALUE;

      /**
       * Use this only to construct de novo RowColumns. Do not use for slice 
       * or clone use clone() for that.
       * @param sequenceLength The number columns in this sequence.
       */
      Column(int sequenceLength) {
        columnIndex = sequenceLength > 0 ? 1 : 0;
        columnOffset = 0;
        lastColumn = sequenceLength;
      }

      @Override
      public final int index() {
        assertOpen();
        return columnIndex;
      }

      @Override
      public final int absoluteIndex() {
        assertOpen();
        return columnIndex + columnOffset;
      }

      @Override
      public final SqlType sqlType() {
        assertOpen();
        assertNotEmpty();
        return sqlType(absoluteIndex());
      }

      /**
       * @param index Absolute index of a column. 
       * @return The SqlType of the column at the specified index.
       */
      abstract SqlType sqlType(int index);
      
      @Override
      public final Class<?> javaType() {
        assertOpen();
        assertNotEmpty();
        return sqlType().getJavaType();
      }

      @Override
      public final long length() {
        assertOpen();
        assertNotEmpty();
        return length(absoluteIndex());
      }

      /**
       * @param index Absolute index of a column. 
       * @return The length of the column at the specified index.
       */
      abstract long length(int index);
      
      @Override
      public final int numberOfValuesRemaining() {
        assertOpen();
        return lastColumn - columnIndex;
      }
      
      @Override
      public final Column at(String id) {
        assertOpen();
        assertNotEmpty();
        
        if (id == null) 
          throw new IllegalArgumentException("id can not be null");
        
        int matchIndex = -1;
        for (int index = 1; index <= lastColumn; index++) {
          String nextId = identifier(index + columnOffset);
          if (nextId.equals(id)) {
            if (matchIndex == -1) {
              matchIndex = index;
            }
            else {
              throw new NoSuchElementException (
                "Multiple columns match the identifier: " + id);
            }
          }
        }
        
        if (matchIndex == -1) {
          throw new NoSuchElementException(
                    "No column matches the identifier: " + id
                    + ". Column.identifier().equals(id) must be true in order"
                    + " to match.");
        }
        columnIndex = matchIndex;
        return this;
      }
      
      @Override
      public final Column at(int index) {
        assertOpen();
        assertNotEmpty();

        final int newIndex = (index >= 0) ? index : (lastColumn + 1) + index;
        if (lastColumn < newIndex) {
          throw new NoSuchElementException(
            "The index specified is beyond the last value."
              + " Specified Index: " + index
              + ", Last Index: " + lastColumn);
        }
        else if (newIndex < 1) {
          throw new NoSuchElementException(
            "The index specified is before the first value"
            + " Specified Index: " + index
            + ", Last Index: " + lastColumn);
        }
        
        columnIndex = newIndex;
        return this;
      }
      
      /**
       * make a clone into a slice
       *
       * @param numValues number of columns in the slice
       * @return this RowColumn as a slice
       */
      private Column asSlice(int numValues) {
        if (numValues > 0) {
          columnOffset = columnOffset + (columnIndex - 1);
          lastColumn = numValues;
        }
        else {
          columnOffset = columnOffset + (columnIndex - 1) + numValues;
          lastColumn = -(numValues);
        }

        columnIndex = 1;
        return this;
      }

      @Override
      public final Column slice(int numValues) {
        assertOpen();
        assertNotEmpty();
        
        if (numValues > numberOfValuesRemaining() + 1) {
          throw new NoSuchElementException(
            "The slice range specified is beyond the last value."
            + "Specified Range: " + numValues 
            + ", Current Index: " + columnIndex
            + ", Last Index: " + lastColumn);
        }
        else if (numValues < 0 && -(numValues) >= columnIndex) {
          throw new NoSuchElementException(
            "The slice range specified is before index 1."
            + "Specified Range: " + numValues 
            + ", Current Index: " + columnIndex);
        }
        else if (numValues == 0) {
          throw new NoSuchElementException("0 is not a valid slice range.");
        }
        
        return this.clone().asSlice(numValues);
      }

      @Override
      public Result.Column clone() {
        assertOpen();
        try {
          return (Result.Column) super.clone();
        } catch (CloneNotSupportedException ex) {
          throw new RuntimeException("TODO", ex);
        }
      }
      
      @Override
      public final void close() {
        isClosed = true;
      }

      @Override
      public final <T> T get(Class<T> type) {
        assertNotEmpty();
        return get(absoluteIndex(), type);
      }

      /**
       * @param index Absolute index of a column.
       * @param type A type of object.
       * @return The value of the column at the specified index as the 
       *   specified type.
       */
      abstract <T> T get(int index, Class<T> type);
      
      @Override
      public final String identifier() {
        assertNotEmpty();
        return identifier(absoluteIndex());
      }
      
      /**
       * @param index Absolute index of a column.
       * @return The identifier of the column at the specified index.
       */
      abstract String identifier(int index);
      
      /**
       * Throws IllegalStateException if this Column has been closed.
       */
      final void assertOpen() {
        if (isClosed) 
          throw new IllegalStateException("Closed");
      }
      
      private void assertNotEmpty() {
        if (lastColumn == 0)
          throw new IllegalStateException("Empty column seqeunce");
      }
    }
    
    static final class RowColumn extends Column 
      implements jdk.incubator.sql2.Result.RowColumn {
        
      private final RowBaseOperation rowOp;
      
      RowColumn(RowBaseOperation op) {
        super(op.getIdentifiers().length);
        rowOp = op;
      }
      
      @Override
      <T> T get(int index, Class<T> type) {
        try {
          return rowOp.resultSet().getObject(index, type);
        } catch (SQLException ex) {
          throw new SqlException(ex.getMessage(), ex, ex.getSQLState(),
                                 ex.getErrorCode(), rowOp.sqlString(), -1);
        }
      }
      
      @Override
      public String identifier(int index) {
          return rowOp.getIdentifiers()[index - 1];
      }

      @Override
      SqlType sqlType(int index) {
        try {
          int jdbcType = rowOp.resultSet.getMetaData()
                           .getColumnType(index);
          return Operation.fromSQLType(JDBCType.valueOf(jdbcType));
        }
        catch (SQLException ex) {
          throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), 
                                 ex.getErrorCode(), rowOp.sqlString(), -1);
        }
      }

      @Override
      long length(int index) {
        try {
          return rowOp.resultSet.getMetaData()
                   .getColumnDisplaySize(index);
        }
        catch (SQLException ex) {
          throw new UnsupportedOperationException(ex);
        }
      }
      
      @Override
      public long rowNumber() {
        assertOpen();
        return rowOp.rowCount(); // keep an independent count because ResultSet.row is limited to int
      }

      @Override
      public void cancel() {
        assertOpen();
        throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
      }
    }
    
    private static final class OutColumn extends Column 
      implements jdk.incubator.sql2.Result.OutColumn {
        
      private final OutOperation outOp;
      
      OutColumn(OutOperation op, int sequenceLength) {
        super(sequenceLength);
        outOp = op;
      }
      
      @Override
      <T> T get(int index, Class<T> type) {
        try {
            return outOp.jdbcCallableStmt()
                     .getObject(index, type);
        }
        catch (SQLException ex) {
          throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), 
                                 ex.getErrorCode(), outOp.sqlString(), -1);
        }
      }

      @Override
      SqlType sqlType(int index) {
        try {
          int jdbcType = outOp.jdbcCallableStmt()
                           .getParameterMetaData()
                           .getParameterType(index);
          return Operation.fromSQLType(JDBCType.valueOf(jdbcType));
        }
        catch (SQLException ex) {
          throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), 
                                 ex.getErrorCode(), outOp.sqlString(), -1);
        }
      }

      @Override
      long length(int index) {
        try {
          return outOp.jdbcCallableStmt()
                   .getParameterMetaData()
                   .getPrecision(index);
        }
        catch (SQLException ex) {
          throw new SqlException(ex.getMessage(), ex, ex.getSQLState(), 
                                 ex.getErrorCode(), outOp.sqlString(), -1);
        }
      }

      @Override
      String identifier(int index) {
        throw new UnsupportedOperationException("TODO");
      }
    }
}
