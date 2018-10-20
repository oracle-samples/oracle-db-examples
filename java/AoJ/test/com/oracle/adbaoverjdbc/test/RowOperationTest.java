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

import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.Session;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collector;
import static org.junit.Assert.*;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import java.util.ArrayList;
import java.util.NoSuchElementException;
import java.util.concurrent.atomic.AtomicInteger;

import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.Result.Column;

import static com.oracle.adbaoverjdbc.test.TestConfig.*;

public class RowOperationTest {

  private static final String TEST_TABLE = "test_table";
  private static final String[] TEST_COLUMNS = { "A", "B", "C" };
  private static final String[][] TEST_DATA = { 
    { "a1", "a2", "a3" }, 
    { "b1", "b2", "b3" }, 
    { "c1", "c2", "c3" }, 
  };

  @BeforeClass
  public static void setup() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      TestFixtures.createTestSchema(se);
      se.operation("CREATE TABLE " + TEST_TABLE + "(" 
                   + TEST_COLUMNS[0] + " VARCHAR(2), " 
                   + TEST_COLUMNS[1] + " VARCHAR(2), "
                   + TEST_COLUMNS[2] + " VARCHAR(2))")
        .onError(e -> e.printStackTrace())
        .submit();
      se.arrayRowCountOperation("INSERT INTO " + TEST_TABLE
                                + " VALUES (?, ?, ?)")
        .set("1", TEST_DATA[0])
        .set("2", TEST_DATA[1])
        .set("3", TEST_DATA[2])
        .onError(e -> e.printStackTrace())
        .submit();
      se.commitMaybeRollback(se.transactionCompletion())
        .toCompletableFuture()
        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    }
  }

  @AfterClass
  public static void teardown() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      TestFixtures.dropTestSchema(se);
      se.operation("DROP TABLE " + TEST_TABLE)
        .onError(e -> e.printStackTrace())
        .submit();
      se.commitMaybeRollback(se.transactionCompletion())
        .toCompletableFuture()
        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    }
  }

  @Test
  public void rowOperation() throws Exception {
    try (DataSource ds = getDataSource(); Session session = ds.getSession()) {
      session.<Integer>rowOperation("select * from forum_user where id = ?")
              .set("1", 7782)
              .collect(Collector.of(
                      () -> null,
                      (a, r) -> {
                        int score = r.at("total_score").get(Integer.class);
                        assertEquals(score, 2450);
                      },
                      (l, r) -> null))
              .onError( t -> fail(t.toString()))
              .submit(); 
            
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }

  /**
   * Verify {@link com.oracle.adbaoverjdbc.Result.RowColumn}'s implementation
   * of Iterable<Column>.
   */
  @Test
  public void testColumnIteration() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {

      AtomicInteger rowCount = new AtomicInteger();
      ArrayList<String> result =
        se.<ArrayList<String>> rowOperation("SELECT * FROM " + TEST_TABLE)
          .collect(ArrayList<String>::new, 
                   (ls, rc) -> {
                     int rowIndex = rowCount.getAndIncrement();
                     assertEquals(rowIndex, rc.rowNumber());
                     assertEquals(TEST_COLUMNS.length - 1, 
                                  rc.numberOfValuesRemaining());

            int colIndex = 0;
            for (Column co : rc) {
              colIndex++;
              validateColumn(rowIndex, co, colIndex, 0, TEST_COLUMNS.length);
              validateColumn(rowIndex, co.clone(), colIndex, 0,
                             TEST_COLUMNS.length);
              ls.add(co.get(String.class));
            }
            assertEquals(TEST_COLUMNS.length, colIndex);
          })
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .get();

      assertEquals(TEST_DATA[0].length, rowCount.get());
      for (int i = 0; i < TEST_DATA.length; i++) {
        for (int j = 0; j < TEST_DATA[0].length; j++) {
          assertEquals(TEST_DATA[j][i], 
                       result.get((i * TEST_DATA.length) + j));
        }
      }
    }
  }

  @Test
  public void testColumnSlice() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {

      AtomicInteger rowCount = new AtomicInteger();

      se.rowOperation("SELECT * FROM " + TEST_TABLE)
        .collect(ArrayList<String>::new, (ls, rc) -> {
          int rowIndex = rowCount.getAndIncrement();
          assertEquals(rowIndex, rc.rowNumber());
          assertEquals(TEST_COLUMNS.length - 1, 
                       rc.numberOfValuesRemaining());
  
          // From the initial column index, test the full range of 
          // valid slice sizes
          for (int sliceSize = 0; sliceSize <= TEST_COLUMNS.length; 
               sliceSize++) {
            if (sliceSize == 0) continue;
            Column sliceSequence = rc.slice(sliceSize);
            int sliceIndex = 0;
            for (Column sliceCo : sliceSequence) {
              validateColumn(rowIndex, sliceCo, ++sliceIndex, 0, sliceSize);
            }
          }

          // From each column index, test the full range of valid slice 
          // sizes.
          int coIndex = 0;
          for (Column co : rc) {
            coIndex++;
            assertEquals(TEST_COLUMNS.length - coIndex,
                         co.numberOfValuesRemaining());
  
            for (int sliceSize = (1 - coIndex); 
                 sliceSize <= TEST_COLUMNS.length - (coIndex - 1); 
                 sliceSize++) {
              if (sliceSize == 0) continue;
              Column sliceSequence = co.slice(sliceSize);
              assertEquals(Math.abs(sliceSize) - 1,
                           sliceSequence.numberOfValuesRemaining());

              // The absolute index of the first column in the sequence.
              int absStartIndex =
                (sliceSize < 0 ? (coIndex + sliceSize) : coIndex);

              int sliceIndex = 0;
              for (Column sliceCo : sliceSequence) {
                sliceIndex++;
                validateColumn(rowIndex, sliceCo, sliceIndex, absStartIndex - 1,
                               Math.abs(sliceSize));
              }
              assertEquals(Math.abs(sliceSize), sliceIndex);
            }
          }
        })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }

  @Test
  public void testInvalidSlice() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {

      AtomicInteger rowCount = new AtomicInteger();

      se.rowOperation("SELECT * FROM " + TEST_TABLE)
        .collect(ArrayList<String>::new, (ls, rc) -> {
          int rowIndex = rowCount.getAndIncrement();
          assertEquals(rowIndex, rc.rowNumber());
          assertEquals(TEST_COLUMNS.length - 1, rc.numberOfValuesRemaining());

          int coIndex = 0;
          for (Column co : rc) {
            coIndex++;
            assertEquals(TEST_COLUMNS.length - coIndex,
                         co.numberOfValuesRemaining());

            // From the current column index, test the invalid ranges.
            try {
              co.slice(-coIndex);
              fail("No exception thrown at call to slice(" + (-coIndex) + ")"
                   + " from column index: " + coIndex);
            } catch (NoSuchElementException expected) {
              /* Expected */
            }

            try {
              co.slice(1 + TEST_COLUMNS.length - (coIndex - 1));
              fail("No exception thrown at call to slice(" + (-coIndex) + ")"
                   + " from column index: " + coIndex);
            } catch (NoSuchElementException expected) {
              /* Expected */
            }

            try {
              co.slice(0);
              fail("No exception thrown at call to slice(0)"
                   + " from column index: " + coIndex);
            } catch (NoSuchElementException expected) {
              /* Expected */
            }
          }
        })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }

  @Test
  public void testColumnForEach() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {

      AtomicInteger rowCount = new AtomicInteger();

      se.rowOperation("SELECT * FROM " + TEST_TABLE)
        .collect(ArrayList<String>::new, (ls, rc) -> {
          int rowIndex = rowCount.getAndIncrement();
          assertEquals(rowIndex, rc.rowNumber());
          assertEquals(TEST_COLUMNS.length - 1, rc.numberOfValuesRemaining());

          AtomicInteger coIndex = new AtomicInteger();
          rc.forEach(co -> {
            validateColumn(rowIndex, co, coIndex.incrementAndGet(), 0,
                           TEST_COLUMNS.length);
          });
        })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }

  @Test
  public void testColumnAt() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {

      AtomicInteger rowCount = new AtomicInteger();

      se.rowOperation("SELECT * FROM " + TEST_TABLE)
        .collect(ArrayList<String>::new, (ls, rc) -> {
          int rowIndex = rowCount.getAndIncrement();
          assertEquals(rowIndex, rc.rowNumber());
          assertEquals(TEST_COLUMNS.length - 1, rc.numberOfValuesRemaining());

          for (int coIndex = 1; coIndex <= TEST_COLUMNS.length; coIndex++) {
            validateColumn(rowIndex, rc.at(coIndex), coIndex, 0,
                           TEST_COLUMNS.length);
            validateColumn(rowIndex, rc.at(TEST_COLUMNS[coIndex - 1]), coIndex,
                           0, TEST_COLUMNS.length);
          }
        })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }

  @Test
  public void testOffsetIteration() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {

      AtomicInteger rowCount = new AtomicInteger();

      se.rowOperation("SELECT * FROM " + TEST_TABLE)
        .collect(ArrayList<String>::new, (ls, rc) -> {
          int rowIndex = rowCount.getAndIncrement();
          assertEquals(rowIndex, rc.rowNumber());
          assertEquals(TEST_COLUMNS.length - 1, rc.numberOfValuesRemaining());
          
          for (int offset = 1; offset <= TEST_COLUMNS.length; offset++) {
            int count = 0;
            Column prev = null;
            for (Column col : rc.at(offset)) {
              validateColumn(rowIndex, col, offset + count, 0, 
                             TEST_COLUMNS.length);
              assertFalse(col == rc);
              assertFalse(col == prev);
              assertEquals(offset, rc.index());
              prev = col;
              count++;
            }
            assertEquals(1 + (TEST_COLUMNS.length - offset), count);
          }
        })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }

  @Test
  public void testInvalidAt() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
  
      AtomicInteger rowCount = new AtomicInteger();
  
      se.rowOperation("SELECT * FROM " + TEST_TABLE)
        .collect(ArrayList<String>::new, (ls, rc) -> {
          int rowIndex = rowCount.getAndIncrement();
          assertEquals(rowIndex, rc.rowNumber());
          assertEquals(TEST_COLUMNS.length - 1, rc.numberOfValuesRemaining());

          try {
            rc.at(TEST_COLUMNS.length + 1);
            fail("Expected NoSuchElementException");
          } catch (NoSuchElementException expected) {
            /* Expected */
          }
          
          try {
            rc.at(0);
            fail("Expected NoSuchElementException");
          } catch (NoSuchElementException expected) {
            /* Expected */
          }
          
          try {
            rc.at(-(TEST_COLUMNS.length + 1));
            fail("Expected NoSuchElementException");
          } catch (NoSuchElementException expected) {
            /* Expected */
          }

          try {
            rc.at("z");
            fail("Expected NoSuchElementException");
          } catch (NoSuchElementException expected) {
            /* Expected */
          }
          
          int coIndex = 0;
          for (Column co : rc) { 
            coIndex++;
            assertEquals(TEST_COLUMNS.length - coIndex,
                         co.numberOfValuesRemaining());

            for (int sliceSize = (1 - coIndex); 
                 sliceSize <= TEST_COLUMNS.length - (coIndex - 1); 
                 sliceSize++) {
              if (sliceSize == 0) continue;
              Column coSlice = co.slice(sliceSize);

              try {
                coSlice.at(Math.abs(sliceSize) + 1);
                fail("Expected NoSuchElementException"
                     + " rc.at(" + coIndex + ")"
                     + ".slice(" + sliceSize + ")"
                     + ".at(" + (sliceSize + 1) + ")");
              } catch (NoSuchElementException expected) {
                /* Expected */
              }

              try {
                coSlice.at(0);
                fail("Expected NoSuchElementException"
                     + " rc.at(" + coIndex + ")"
                     + ".slice(" + sliceSize + ")"
                     + ".at(0)");
              } catch (NoSuchElementException expected) {
                /* Expected */
              }

              try {
                coSlice.at(-(Math.abs(sliceSize) + 1));
                fail("Expected NoSuchElementException"
                     + " rc.at(" + coIndex + ")"
                     + ".slice(" + sliceSize + ")"
                     + ".at(" + -(sliceSize + 1) + ")");
              } catch (NoSuchElementException expected) {
                /* Expected */
              }

              for (int i = 1; i <= TEST_COLUMNS.length; i++) {
                if (sliceSize > 0 && i >= coIndex && i < coIndex + sliceSize)
                  continue; // Skip valid columns
                if (sliceSize < 0 && i < coIndex && i >= coIndex + sliceSize)
                  continue; // Skip valid columns
                
                try {
                  coSlice.at(TEST_COLUMNS[i - 1]);
                  fail("Expected NoSuchElementException when calling"
                       + " rc.at(" + coIndex + ")"
                       + ".slice(" + sliceSize + ")"
                       + ".at(\"" + TEST_COLUMNS[i-1] + "\")");
                } catch (NoSuchElementException expected) {
                  /* Expected */
                }  
              } 
            }
          }
        })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }
  
//  @Test TODO: Need procedural SQL for test suite
  public void testNoColumns() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      se.outOperation("Procedureal SQL here")
        .apply(out -> {
          assertEquals(0, out.index());
          assertEquals(0, out.absoluteIndex());
          assertEquals(0, out.numberOfValuesRemaining());
          assertFalse(out.hasNext());
          out.forEach(c -> fail("No invocation expected."));
          out.forEachRemaining(c -> fail("No invocation expected."));
          try {
            out.at(1);
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            out.at(TEST_COLUMNS[0]);
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            out.get();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            out.get(String.class);
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            out.identifier();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            out.javaType();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            out.length();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          
          Column outClone = out.clone();
          assertEquals(0, outClone.index());
          assertEquals(0, outClone.absoluteIndex());
          assertEquals(0, outClone.numberOfValuesRemaining());
          assertFalse(outClone.hasNext());
          outClone.forEach(c -> fail("No invocation expected."));
          outClone.forEachRemaining(c -> fail("No invocation expected."));
          try {
            outClone.at(1);
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            outClone.at(TEST_COLUMNS[0]);
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            outClone.get();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            outClone.get(String.class);
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            outClone.identifier();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            outClone.javaType();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          try {
            outClone.length();
            fail("IllegalStateException was expected");
          }
          catch(IllegalStateException expected) { /*expected*/}
          return null;
        })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }
  
  @Test
  public void testDuplicateColumns() throws Exception {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      se.rowOperation("SELECT " + TEST_COLUMNS[0] 
                      + ", " + TEST_COLUMNS[1] + " AS " + TEST_COLUMNS[0]
                      + " FROM " + TEST_TABLE)
        .collect(() -> null,
                 (nil, row) -> {
                   assertEquals(TEST_COLUMNS[0], row.at(1).identifier());
                   assertEquals(TEST_COLUMNS[0], row.at(2).identifier());
                   try {
                     row.at(TEST_COLUMNS[0]);
                     fail("Expected NoSuchElementException if two columns"
                       + " match the same identifier.");
                   }
                   catch (NoSuchElementException expected) { /* expected */ }
                 })
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }
  
  private void validateColumn(int row, Column col, int index, int offset,
                              int length) {
    assertEquals(length - index, col.numberOfValuesRemaining());
    assertEquals(index, col.index());
    assertEquals(index + offset, col.absoluteIndex());

    int absZeroBasedIndex = (index - 1) + offset;
    String expectedData = TEST_DATA[absZeroBasedIndex][row];
    assertEquals(expectedData, col.get());
    assertEquals(expectedData, col.get(String.class));
    assertEquals(AdbaType.VARCHAR, col.sqlType());
    assertEquals(String.class, col.javaType()); // VARCHAR : String
    assertEquals(2, col.length()); // VARCHAR(2)
    assertEquals(TEST_COLUMNS[absZeroBasedIndex].replace("\"", ""),
                 col.identifier());
  }
}
