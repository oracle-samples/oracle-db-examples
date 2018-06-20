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
import jdk.incubator.sql2.Connection;
import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.Transaction;
import java.util.Properties;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collector;
import org.junit.After;
import org.junit.AfterClass;
import org.junit.Before;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;
import static com.oracle.adbaoverjdbc.JdbcConnectionProperties.JDBC_CONNECTION_PROPERTIES;
import jdk.incubator.sql2.Result;

/**
 * This is a quick and dirty test to check if anything at all is working.
 * 
 * Depends on the scott/tiger schema availble here:
 * https://github.com/oracle/dotnet-db-samples/blob/master/schemas/scott.sql
 */
public class FirstLight {
  
  //
  // EDIT THESE
  //
  // Define these three constants with the appropriate values for the database
  // and JDBC driver you want to use. Should work with ANY reasonably standard
  // JDBC driver. These values are passed to DriverManager.getConnection.
  public static final String URL = "jdbc:oracle:thin:@//den03cll.us.oracle.com:5521/main2.regress.rdbms.dev.us.oracle.com"; //"<JDBC driver connect string>";
  public static final String USER = "scott"; //<database user name>";
  public static final String PASSWORD = "tiger"; //<database user password>";
  // Define this to be the most trivial SELECT possible
  public static final String TRIVIAL = "SELECT 1 FROM DUAL";

  
  public static final String FACTORY_NAME = "com.oracle.adbaoverjdbc.DataSourceFactory";
  
  public FirstLight() {
  }

  @BeforeClass
  public static void setUpClass() {
  }

  @AfterClass
  public static void tearDownClass() {
  }

  @Before
  public void setUp() {
  }

  @After
  public void tearDown() {
  }

  /**
   * Verify that DataSourceFactory.forName works. Can't do anything without that.
   */
  @Test
  public void firstLight() {
    assertEquals("com.oracle.adbaoverjdbc.DataSourceFactory",
            DataSourceFactory.newFactory(FACTORY_NAME).getClass().getName());
  }
  
  /**
   * Verify that can create a DataSource, though not a Connection. Should work
   * even if there is no database.
   */
  @Test
  public void createDataSource() {
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
    assertNotNull(ds);
  }
  
  /**
   * create a Connection and send a SQL to the database
   */
  @Test
  public void sqlOperation() {
    Properties props = new Properties();
    props.setProperty("oracle.jdbc.implicitStatementCacheSize", "10");
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .connectionProperty(JDBC_CONNECTION_PROPERTIES, props)
            .build();
    Connection conn = ds.getConnection(t -> System.out.println("ERROR: " + t.getMessage()));
    try (conn) {
      assertNotNull(conn);
      conn.operation(TRIVIAL).submit();
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  /**
   * Execute a few trivial queries. 
   */
  @Test
  public void rowOperation() {
    Properties props = new Properties();
    props.setProperty("oracle.jdbc.implicitStatementCacheSize", "10");
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .connectionProperty(JDBC_CONNECTION_PROPERTIES, props)
            .build();
            Connection conn = ds.getConnection(t -> System.out.println("ERROR: " + t.getMessage()))) {
      assertNotNull(conn);
      conn.<Void>rowOperation(TRIVIAL)
              .collect(Collector.of(() -> null,
                                    (a, r) -> {
                                      System.out.println("Trivial: " + r.at(1).get(String.class));
                                    },
                                    (x, y) -> null))
              .submit();
      conn.<Integer>rowOperation("select * from emp")
              .collect(Collector.<Result.RowColumn, int[], Integer>of(() -> new int[1],
                      (int[] a, Result.RowColumn r) -> {
                        a[0] = a[0]+r.at("sal").get(Integer.class);
                      },
                      (l, r) -> l,
                      a -> (Integer)a[0]))
              .submit()
              .getCompletionStage()
              .thenAccept( n -> {System.out.println("labor cost: " + n);})
              .toCompletableFuture();
      conn.<Integer>rowOperation("select * from emp where empno = ?")
              .set("1", 7782)
              .collect(Collector.of(
                      () -> null,
                      (a, r) -> {
                        System.out.println("salary: $" + r.at("sal").get(Integer.class));
                      },
                      (l, r) -> null))
              .submit();
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  /**
   * check does error handling do anything
   */
  @Test
  public void errorHandling() {
    Properties props = new Properties();
    props.setProperty("oracle.jdbc.implicitStatementCacheSize", "10");
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password("invalid password")
            .connectionProperty(JDBC_CONNECTION_PROPERTIES, props)
            .build();
            Connection conn = ds.getConnection(t -> System.out.println("ERROR: " + t.toString()))) {
      conn.<Void>rowOperation(TRIVIAL)
              .collect(Collector.of(() -> null,
                                    (a, r) -> {
                                      System.out.println("Trivial: " + r.at(1).get(String.class));
                                    },
                                    (x, y) -> null))
              .onError( t -> { System.out.println(t.toString()); })
              .submit();
    }
    
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .connectionProperty(JDBC_CONNECTION_PROPERTIES, props)
            .build();
            Connection conn = ds.getConnection(t -> System.out.println("ERROR: " + t.toString()))) {
      conn.<Integer>rowOperation("select * from emp where empno = ?")
              .set("1", 7782)
              .collect(Collector.of(
                      () -> null,
                      (a, r) -> {
                        System.out.println("salary: $" + r.at("sal").get(Integer.class));
                      },
                      (l, r) -> null))
              .onError( t -> { System.out.println(t.getMessage()); } )
              .submit();
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  /**
   * Do something that approximates real work. Do a transaction. Uses
   * Transaction, CompletionStage args, and catch Operation.
   */
  @Test
  public void transaction() {
    Properties props = new Properties();
    props.setProperty("oracle.jdbc.implicitStatementCacheSize", "10");
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .connectionProperty(JDBC_CONNECTION_PROPERTIES, props)
            .build();
            Connection conn = ds.getConnection(t -> System.out.println("ERROR: " + t.toString()))) {
      Transaction trans = conn.transaction();
      CompletionStage<Integer> idF = conn.<Integer>rowOperation("select empno, ename from emp where ename = ? for update")
              .set("1", "CLARK", AdbaType.VARCHAR)
              .collect(Collector.of(
                      () -> new int[1], 
                      (a, r) -> {a[0] = r.at("empno").get(Integer.class); },
                      (l, r) -> null,
                      a -> a[0])
              )
              .submit()
              .getCompletionStage();
      idF.thenAccept( id -> { System.out.println("id: " + id); } );
      conn.<Long>rowCountOperation("update emp set deptno = ? where empno = ?")
              .set("1", 50, AdbaType.INTEGER)
              .set("2", idF, AdbaType.INTEGER)
              .apply(c -> { 
                if (c.getCount() != 1L) {
                  trans.setRollbackOnly();
                  throw new SqlException("updated wrong number of rows", null, null, -1, null, -1);
                }
                return c.getCount();
              })
              .onError(t -> t.printStackTrace())
              .submit()
              .getCompletionStage()
              .thenAccept( c -> { System.out.println("updated rows: " + c); } );
      conn.catchErrors();
      conn.commitMaybeRollback(trans);
    }    
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
}
