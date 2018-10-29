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

import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.MultiOperation;
import jdk.incubator.sql2.OperationGroup;
import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.Submission;

import java.sql.Date;
import java.util.ArrayList;
import java.util.List;
import java.util.Properties;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.Flow;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.function.BiConsumer;
import java.util.stream.Collector;

import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;

import static org.junit.Assert.*;
import static com.oracle.adbaoverjdbc.JdbcConnectionProperties.JDBC_CONNECTION_PROPERTIES;
import jdk.incubator.sql2.Result;
import jdk.incubator.sql2.RowCountOperation;
import jdk.incubator.sql2.RowOperation;
import jdk.incubator.sql2.RowPublisherOperation;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.TransactionCompletion;

/**
 * This is a quick and dirty test to check if anything at all is working.
 * 
 */
public class MultiOperationTest {
  
  // Define these three constants with the appropriate values for the database
  // and JDBC driver you want to use. Should work with ANY reasonably standard
  // JDBC driver. These values are passed to DriverManager.getSession.
  public static final String URL = TestConfig.getUrl();
  public static final String USER = TestConfig.getUser();
  public static final String PASSWORD = TestConfig.getPassword();
  private static final String PROC_NAME = "multi_op_emp_by_num";
  

  public static final String FACTORY_NAME = 
      TestConfig.getDataSourceFactoryName();
  
  
  @BeforeClass
  public static void setUpClass() {
    try (DataSource ds = TestConfig.getDataSource(); 
         Session se = ds.getSession()) {
        TestFixtures.createTestSchema(se);
//      createOutOpProc(se);
      }
  }

  @AfterClass
  public static void tearDownClass() {
    try (DataSource ds = TestConfig.getDataSource();
         Session se = ds.getSession()) {
      TestFixtures.dropTestSchema(se);
//    dropOutOpProc(se);    
    }
  }
  
  /**
   * Execute a query returning a single result. 
   */
  @Test
  public void multiRowOperation() {
    fail("TODO: Fix this test");
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> fail("ERROR: " + t.getMessage()))) {
      assertNotNull(session);
      MultiOperation multiOp = session.multiOperation("select * from forum_user")
                                      .onError( t -> { fail(t.toString()); });

      
      RowOperation rowOp = multiOp.<Integer>rowOperation();

      multiOp.submit();
      
      rowOp.collect(Collector.<Result.RowColumn, int[], Integer>of(() -> new int[1],
                      (int[] a, Result.RowColumn r) -> {
                        a[0] = a[0]+r.at("sal").get(Integer.class);
                      },
                      (l, r) -> l,
                      a -> (Integer)a[0]))
          .onError( t -> { fail(t.toString()); })
          .submit()
          .getCompletionStage()
          .thenAccept( n -> {assertTrue(((long)n > 0));})
          .toCompletableFuture()
          .get(TestConfig.getTimeout().toMillis(), TimeUnit.MILLISECONDS);
      
    } catch (Exception e) {
      fail(e.getMessage());
      e.printStackTrace();
    }
  }
  
  /**
   * Do something that approximates real work. Do a transaction. Uses
   * TransactionCompletion, CompletionStage args, and catch Operation.
   */
  @Test
  public void multiRowCountOperation() throws Exception {
    fail("TODO: Fix this test");
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> fail("ERROR: " + t.getMessage()))) {
      assertNotNull(session);
      TransactionCompletion trans = session.transactionCompletion();
      
      MultiOperation multiOp = session.multiOperation("update forum_user set city_id = ?"
                                                      + " where id = ?")
                                      .set("1", 40, AdbaType.INTEGER)
                                      .set("2", 7782, AdbaType.INTEGER)
                                      .onError( t -> { System.out.println(t.toString()); });
      
      RowCountOperation<Long> cntOp = multiOp.<Long>rowCountOperation();
      
      multiOp.submit();
      
      cntOp.apply(c -> { 
            long count = c.getCount();
            if (count != 1L)
              throw new SqlException("updated wrong number of rows", null, null, -1, null, -1);
            return count;
          })
          .onError(t -> t.printStackTrace())
          .submit()
          .getCompletionStage()
          .thenAccept( c -> { assertTrue((long)c > 0); } );

      session.catchErrors();
      session.rollback()
        .toCompletableFuture()
        .get(TestConfig.getTimeout().toMillis(),
             TimeUnit.MILLISECONDS);
    }
  }
  
  @Test
  public void multiRowPublisherOperation() throws Exception {
    fail("TODO: Fix this test");
    String sql = "select id, name from forum_user";
    CompletableFuture<List<String>> result = new CompletableFuture<>();
    CompletionStage<List<String>> cs = null;
    
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> fail("ERROR: " + t.getMessage()))) {
      assertNotNull(session);
      MultiOperation multiOp = session.multiOperation(sql)
                                      .onError( t -> { fail(t.toString()); });
      
      RowPublisherOperation rowPublisherOp =  multiOp.rowPublisherOperation();
      
      multiOp.submit();
    
      Flow.Subscriber<Result.RowColumn> subscriber = getSubscriber(result, false);
      cs = rowPublisherOp
            .subscribe(subscriber, result)
            .onError(e -> fail(e.toString()))
            .timeout(TestConfig.getTimeout())
            .submit()
            .getCompletionStage(); 
    } catch (Exception e) {
      fail(e.getMessage());
    }

    List<String> names = result.get(TestConfig.getTimeout().toMillis(), 
                                    TimeUnit.MILLISECONDS);
    assertTrue(names != null && !names.isEmpty());
  }
  
 
//  @Test TODO: Test suite needs procedural SQL for any database
  public void multiOutOperationTest() {
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);

    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> fail("ERROR: " + t.toString()))) {

        final int empno = 7369;
        invokeOutOpProc(session, empno);
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  /**
   * Execute a query returning a single result. 
   */
  @Test
  public void multiRowOperationWithRowHandler() {
    fail("TODO: Fix this test");
    Properties props = new Properties();
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .sessionProperty(JDBC_CONNECTION_PROPERTIES, props)
            .build();
            Session session = ds.getSession(t -> fail("ERROR: " + t.getMessage()))) {
      assertNotNull(session);
      MultiOperation multiOp = session.multiOperation("select * from forum_user")
                                      .onError( t -> { fail(t.toString()); });
      BiConsumer<Integer, RowOperation<Integer>> rowHandler 
                                                  = (resNum, rowOp) -> {
                                                      assertTrue(resNum > 0);
                                                      rowOp.collect(Collector.<Result.RowColumn, int[], Integer>of(() -> new int[1],
                                                            (int[] a, Result.RowColumn r) -> {
                                                            a[0] = a[0]+r.at("sal").get(Integer.class);
                                                            },
                                                            (l, r) -> l,
                                                            a -> (Integer)a[0]))
                                                          .onError( t -> { fail(t.toString()); })
                                                          .submit()
                                                          .getCompletionStage()
                                                          .thenAccept( n -> {assertTrue((long)n > 0);})
                                                          .toCompletableFuture();
                                                    };

      

      multiOp
        .onRows(rowHandler)
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get(TestConfig.getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    } catch (Exception e) {
      fail(e.getMessage());
    }
  }
  
  @Test
  public void multiRowCountOperationWithCountHandler() throws Exception {
    fail("TODO: Fix this test");
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> fail("ERROR: " + t.getMessage()))) {
      assertNotNull(session);
      BiConsumer<Integer, RowCountOperation<Long>> countHandler = 
                                                  (resNum, cntOp) -> {
                                                    assertTrue(resNum > 0);
                                                    cntOp.apply(c -> { 
                                                      long count = c.getCount();
                                                      if (count != 1L)
                                                        fail("updated wrong number of rows");
                                                      return count;
                                                    })
                                                    .onError(t -> fail(t.toString()))
                                                    .submit()
                                                    .getCompletionStage()
                                                    .thenAccept( c -> { assertTrue(c > 0); } );
                                                  };
      
      
      MultiOperation multiOp = session.multiOperation("update forum_user"
                                                      + " set city_id = ?"
                                                      + " where id = ?")
                                      .set("1", 40, AdbaType.INTEGER)
                                      .set("2", 7782, AdbaType.INTEGER)
                                      .onError( t -> { fail(t.toString()); });
      
      
      multiOp
        .onCount(countHandler)
        .submit();
      

      session.catchErrors();
      session.rollback()
        .toCompletableFuture()
        .get(TestConfig.getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    }
  }
  
  
  private Flow.Subscriber<Result.RowColumn> getSubscriber(CompletableFuture<List<String>> result, 
                                                          boolean reqOnThread) {
    
    Flow.Subscriber<Result.RowColumn> subscriber = new Flow.Subscriber<>() {

      Flow.Subscription subscription;
      List<String> names = new ArrayList<>();
      int demand = 0;
      final int BATCH_REQUEST_COUNT = 3;
      final boolean requestOnThread = reqOnThread;

      @Override
      public void onSubscribe(Flow.Subscription subscription) {
        this.subscription = subscription;
        this.subscription.request(BATCH_REQUEST_COUNT);
        demand = BATCH_REQUEST_COUNT;
      }

      @Override
      public void onNext(Result.RowColumn column) {
        String name = column.at("NAME").get(String.class);
        System.out.println(name);
        names.add(name);
        if (--demand < 1) {
          if(requestOnThread) {
            new Thread(new RequestGenerator()).start();
          }
          else {
            subscription.request(BATCH_REQUEST_COUNT);
            demand = BATCH_REQUEST_COUNT;
          }
        }
      }

      @Override
      public void onError(Throwable throwable) {
        result.completeExceptionally(throwable);
      }

      @Override
      public void onComplete() {
        result.complete(names);
      }
      
    class RequestGenerator implements Runnable {
      @Override
      public void run() {
        try{
          Thread.sleep(500);
        } catch(InterruptedException ex) {}
        
        subscription.request(BATCH_REQUEST_COUNT);
        demand = BATCH_REQUEST_COUNT;
      }
    }
      
    };
    
   return subscriber;
  }
  
  
  private static void submitSQL(OperationGroup<?,?> opGroup, String... sqls) {
    for (String sql : sqls) {
      opGroup.operation(sql)
        .timeout(TestConfig.getTimeout())
        .onError(err -> System.err.println(sql + " : " + err.getMessage()))
        .submit();
      opGroup.catchErrors();
    }
    commit((Session)opGroup);
  }
  
  private static void commit(Session session) {
    try {
      session.endTransactionOperation(session.transactionCompletion())
        .timeout(TestConfig.getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
  
  private static void createOutOpProc(Session session) {
    String sql = 
            "CREATE OR REPLACE PROCEDURE "+PROC_NAME+"(given_num IN NUMBER, "
                                                    + "out_name OUT VARCHAR2, "
                                                    + "out_job OUT VARCHAR2, "
                                                    + "out_mgr OUT NUMBER, "
                                                    + "out_hiredate OUT DATE, "
                                                    + "out_sal OUT NUMBER, "
                                                    + "out_comm OUT NUMBER, "
                                                    + "out_deptno OUT NUMBER) IS "
            + "BEGIN "
                + "SELECT ename, job, mgr, hiredate, sal, comm, deptno "
                    + "INTO out_name, out_job, out_mgr, out_hiredate, out_sal, out_comm, out_deptno "
                    + "FROM EMP WHERE empno=given_num; "
            + "END; ";
    
    session.operation(sql).submit();
  }

  private void invokeOutOpProc(Session session, int empNo) {
      String sql = "CALL "+PROC_NAME+"(?, ?, ?, ?, ?, ?, ?, ?) ";
  
      Submission<Employee> submission = session.<Employee>multiOperation(sql)
              .set("1", empNo, AdbaType.INTEGER)
              .outParameter("2", AdbaType.VARCHAR)
              .outParameter("3", AdbaType.VARCHAR)
              .outParameter("4", AdbaType.INTEGER)
              .outParameter("5", AdbaType.DATE)
              .outParameter("6", AdbaType.INTEGER)
              .outParameter("7", AdbaType.INTEGER)
              .outParameter("8", AdbaType.INTEGER)
              .apply(out -> {
                  return new Employee(empNo,
                          out.at(2).get(String.class),
                          out.at(3).get(String.class),
                          out.at(4).get(Integer.class),
                          out.at(5).get(Date.class),
                          out.at(6).get(Integer.class),
                          out.at(7).get(Integer.class),
                          out.at(8).get(Integer.class));
              })
              .onError( t -> { System.out.println(t.toString()); })
              .submit();
  
      CompletableFuture<Employee> cf = submission.getCompletionStage().toCompletableFuture();
      cf.thenAccept(emp -> {
          System.out.println("Emp Record : " + emp);
      });
  }

  private static void dropOutOpProc(Session session) {
      String sql = "DROP PROCEDURE "+PROC_NAME;
      session.operation(sql).submit();
  }

  static public class Employee {
      private final int empNo;
      private final String eName;
      private final String job;
      private final int mgr;
      private final Date hireDate;
      private final int sal;
      private final int comm;
      private final int deptNo;
      
      public Employee(Integer empNo, String eName, String job, Integer mgr, Date hireDate, Integer sal, Integer comm, Integer deptNo) {
          this.empNo = empNo==null?0:empNo;
          this.eName = eName;
          this.job = job;
          this.mgr = mgr==null?0:mgr;
          this.hireDate = hireDate;
          this.sal = sal==null?0:sal;
          this.comm = comm==null?0:comm;
          this.deptNo = deptNo==null?0:deptNo;
      }
      
      @Override
      public String toString() {
          return "\nEMPNO: " + empNo 
                  + "\nENAME: " + eName 
                  + "\nJOB: " + job 
                  + "\nMGR: " + mgr 
                  + "\nHIREDATE: " + hireDate 
                  + "\nSAL: " + sal 
                  + "\nCOMM: " + comm 
                  + "\nDEPTNO: " + deptNo;
      }
  }
}
