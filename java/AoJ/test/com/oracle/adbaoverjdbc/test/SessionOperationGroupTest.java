package com.oracle.adbaoverjdbc.test;

import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.ArrayRowCountOperation;
import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.Result;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.SqlSkippedException;
import jdk.incubator.sql2.Submission;
import jdk.incubator.sql2.TransactionOutcome;

import static com.oracle.adbaoverjdbc.test.TestConfig.*;
import static org.junit.Assert.assertEquals;
import static org.junit.Assert.assertFalse;
import static org.junit.Assert.assertNotNull;
import static org.junit.Assert.assertNull;
import static org.junit.Assert.assertTrue;

import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.function.BiConsumer;
import java.util.function.BinaryOperator;
import java.util.function.Function;
import java.util.function.Supplier;
import java.util.stream.Collector;
import java.util.stream.Collectors;

/**
 * Verifies the Session class implements the public API of OperationGroup as
 * described in the javadoc.
 */
public class SessionOperationGroupTest {
  
  private static final String TABLE = "test_table";
  
  @BeforeClass
  public static void setup() throws Exception {
    try (DataSource ds = TestConfig.getDataSource();
         Session se = ds.getSession()) {
      se.operation("CREATE TABLE " + TABLE + "(c VARCHAR(1))")
        .timeout(getTimeout())
        .submit();
      se.endTransactionOperation(se.transactionCompletion())
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }
  
  @AfterClass
  public static void teardown() throws Exception {
    try (DataSource ds = TestConfig.getDataSource();
         Session se = ds.getSession()) {
      se.operation("DROP TABLE " + TABLE)
        .timeout(getTimeout())
        .submit();
      se.endTransactionOperation(se.transactionCompletion())
        .timeout(getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
  }
  
  /**
   * Verify {@link Session#arrayRowCountOperation()} returns an instance of 
   * ArrayRowCountOperation. The returned instance is only verified
   * for basic functionality.
   * @throws Exception
   */
  @Test
  public void arrayRowCountOperationTest() throws Exception {
    try (DataSource ds = TestConfig.getDataSource();
         Session se = ds.getSession()) {
      
      ArrayRowCountOperation<Long> arcOp = se.<Long>arrayRowCountOperation(
        "INSERT INTO " + TABLE + " VALUES (?)");
      assertNotNull(arcOp);
      
      String[] values = {"x", "y"};
      long count = 
        arcOp.set("1", values, AdbaType.VARCHAR)
          .collect(Collectors.summingLong(Result.RowCount::getCount))
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .get();
      assertEquals(2L, count);
      
      se.rollback()
        .toCompletableFuture()
        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    }
  }
  
  /**
   * Verify {@link Session#catchErrors()} and {@link Session#catchOperation()}
   * creates and/or submits a catch operation.
   * @throws Exception
   */
  @Test
  public void catchOperationTest() throws Exception {
    try (DataSource ds = TestConfig.getDataSource();
         Session se = ds.getSession()) {
      
      AtomicBoolean gotErr = new AtomicBoolean();
      se.operation("SELECT COUNT(*) FROM gg" + TABLE)
        .timeout(getTimeout())
        .onError(err -> gotErr.set(true))
        .submit();

      CompletableFuture<Boolean> gotSkipped = 
        se.operation("SELECT COUNT(*) FROM " + TABLE)
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .handle((nil, err) -> {
            return err instanceof CompletionException
              && err.getCause() instanceof SqlSkippedException; 
          });
      
      List<Integer> count = 
        se.catchErrors()
          .<List<Integer>>rowOperation("SELECT COUNT(*) FROM " + TABLE)
          .collect(Collectors.mapping(row -> row.at(1).get(Integer.class), 
                                      Collectors.toList()))
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .get();
      assertTrue(gotErr.get());
      assertTrue(gotSkipped.get());
      assertNotNull(count);
      assertEquals(1, count.size());
      assertEquals(0, count.get(0).intValue());
      
      // Repeat using catchOperation() rather than catchErrors()
      AtomicBoolean gotErr2 = new AtomicBoolean();
      se.operation("SELECT COUNT(*) FROM gg" + TABLE)
        .timeout(getTimeout())
        .onError(err -> gotErr2.set(true))
        .submit();

      CompletableFuture<Boolean> gotSkipped2 = 
        se.operation("SELECT COUNT(*) FROM " + TABLE)
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .handle((nil, err) -> {
            return err instanceof CompletionException
              && err.getCause() instanceof SqlSkippedException; 
          });
      
      se.catchOperation()
        .submit();
      
      List<Integer> count2 =
        se.<List<Integer>>rowOperation("SELECT COUNT(*) FROM " + TABLE)
          .collect(Collectors.mapping(row -> row.at(1).get(Integer.class), 
                                      Collectors.toList()))
          .timeout(getTimeout())
          .submit()
          .getCompletionStage()
          .toCompletableFuture()
          .get();
      assertTrue(gotErr2.get());
      assertTrue(gotSkipped2.get());
      assertNotNull(count2);
      assertEquals(1, count2.size());
      assertEquals(0, count2.get(0).intValue());
    }
  }
  
  /**
   * Verify basic functionality of 
   * {@link Session#collect(java.util.stream.Collector)}
     * @throws java.lang.Exception
   */
  @Test
  public void testCollect() throws Exception {
    Submission<Object> seSubmission = null;
    
    try (DataSource ds = TestConfig.getDataSource();
      Session se = ds.builder().build()) {      
      Collector<Object, ?, Object> co = new ObjectCollector();

      se.attachOperation()
        .timeout(getTimeout())
        .submit(); // 1
      se.collect(co)
        .localOperation()
        .onExecution(() -> 99)
        .submit(); // 2
      se.rowOperation("SELECT COUNT(*) FROM " + TABLE)
        .collect(Collectors.summingInt(row -> row.at(1).get(Integer.class)))
        .timeout(getTimeout())
        .submit(); // 3
      se.endTransactionOperation(se.transactionCompletion())
        .submit(); // 4
      seSubmission = se.submit();
    } // se.closeOperation().submit() // 5
    
    assertNotNull(seSubmission);
    
    @SuppressWarnings("unchecked")
    List<Integer> result = 
      (List<Integer>) seSubmission
                        .getCompletionStage()
                        .toCompletableFuture()
                        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    assertNotNull(result);
    
    // Note the inline comments which count each submit (1, 2, 3...). This is 
    // the expected count of accumulated results.
    assertEquals(5, result.size());
    assertNull(result.get(0)); // Attach operation
    assertEquals(99, result.get(1).intValue()); // Local operation
    assertEquals(0, result.get(2).intValue()); // Row operation
    assertEquals(TransactionOutcome.COMMIT,
                 result.get(3)); // Transaction operation
    assertNull(result.get(4)); // Close operation
  }
  
  @Test
  public void testTrueConditonal() throws Exception {
    Submission<Object> seSubmission;
    AtomicBoolean opExecuted = new AtomicBoolean();
    
    try (DataSource ds = getDataSource(); 
         Session se = ds.builder().build()) {
      se.conditional(CompletableFuture.completedFuture(true));
      se.attachOperation()
        .submit();
      se.localOperation()
        .onExecution(() -> {
          opExecuted.set(true);
          return null;
        })
        .submit();
      seSubmission =  
        se.collect(new ObjectCollector())
          .submit();
    }
    
    Object result =
      seSubmission.getCompletionStage()
        .toCompletableFuture()
        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    assertTrue(opExecuted.get());
    assertNotNull(result);
  }
  
  @Test
  public void testFalseConditonal() throws Exception {
    try (DataSource ds = getDataSource(); 
         Session se = ds.builder().build()) {
      se.conditional(CompletableFuture.completedFuture(false));
      se.attachOperation()
        .submit();
      
      AtomicBoolean opExecuted = new AtomicBoolean();
      se.localOperation()
        .onExecution(() -> {
          opExecuted.set(true);
          return null;
        })
        .submit();

      Object result = se.collect(new ObjectCollector())
                        .submit()
                        .getCompletionStage()
                        .toCompletableFuture()
                        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
      assertFalse(opExecuted.get());
      assertNull(result);
    }
  }
  
  @Test
  public void testExceptionalConditonal() throws Exception {
    try (DataSource ds = getDataSource(); 
         Session se = ds.builder().build()) {
      se.conditional(CompletableFuture.failedFuture(new RuntimeException()));
      se.attachOperation()
        .submit();
      
      AtomicBoolean opExecuted = new AtomicBoolean();
      se.localOperation()
        .onExecution(() -> {
          opExecuted.set(true);
          return null;
        })
        .submit();

      Object result = se.collect(new ObjectCollector())
                        .submit()
                        .getCompletionStage()
                        .toCompletableFuture()
                        .get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
      assertFalse(opExecuted.get());
      assertNull(result);
    }
  }
    
  /**
   * A {@code Collector<Object, List<Object>, List<Object>>}. It's finisher 
   * type, R, is declared as Object so that it will be accepted by 
   * {@link Session#collect(Collector)}.
   * <br> 
   * This works around a TODO for the ADBA API. The Session interface 
   * implements OperationGroup<Object, Object>.
   */
  static class ObjectCollector 
    implements Collector<Object, List<Object>, Object>  {

    @Override
    public Supplier<List<Object>> supplier() {
      return () -> new ArrayList<Object>();
    }

    @Override
    public BiConsumer<List<Object>, Object> accumulator() {
      return (l, o) -> l.add(o);
    }

    @Override
    public BinaryOperator<List<Object>> combiner() {
      return (o1, o2) -> {
        List<Object> l1 = (List<Object>)o1;
        List<Object> l2 = (List<Object>)o2;
        List<Object> ret = new ArrayList<Object>(l1.size() + l2.size());
        ret.addAll(l1);
        ret.addAll(l2);
        return ret;
      };
    }

    @Override
    public Function<List<Object>, Object> finisher() {
      return l -> l;
    }

    @Override
    public Set<Characteristics> characteristics() {
      return Collections.emptySet();
    }
  } 
}
