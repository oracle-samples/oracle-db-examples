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
import jdk.incubator.sql2.DataSource;
import java.util.Properties;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collector;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;
import static com.oracle.adbaoverjdbc.JdbcConnectionProperties.JDBC_CONNECTION_PROPERTIES;
import jdk.incubator.sql2.Result;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.TransactionCompletion;
import static com.oracle.adbaoverjdbc.test.TestConfig.*;

/**
 * This is a quick and dirty test to check if anything at all is working.
 */
public class FirstLight {
  
  // Define these three constants with the appropriate values for the database
  // and JDBC driver you want to use. Should work with ANY reasonably standard
  // JDBC driver. These values are passed to DriverManager.getSession.
  public static final String URL = TestConfig.getUrl();
  public static final String USER = TestConfig.getUser();
  public static final String PASSWORD = TestConfig.getPassword();
  // Define this to be the most trivial SELECT possible
  public static final String TRIVIAL = "SELECT 1 FROM dummy";

  
  public static final String FACTORY_NAME = 
    TestConfig.getDataSourceFactoryName();

  @BeforeClass
  public static void setUpClass() throws Exception {
    try (DataSource ds = DataSourceFactory.newFactory(FACTORY_NAME)
                           .builder()
                           .url(URL)
                           .username(USER)
                           .password(PASSWORD)
                           .build();
         Session se = ds.getSession()) {
      TestFixtures.createDummyTable(se);
      TestFixtures.createTestSchema(se);
    }
  }

  @AfterClass
  public static void tearDownClass() throws Exception {
    try (DataSource ds = DataSourceFactory.newFactory(FACTORY_NAME)
                           .builder()
                           .url(URL)
                           .username(USER)
                           .password(PASSWORD)
                           .build();
         Session se = ds.getSession()) {
      TestFixtures.dropDummyTable(se);
      TestFixtures.dropTestSchema(se);
    }
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
   * Verify that can create a DataSource, though not a Session. Should work
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
   * create a Session and send a SQL to the database
   */
  @Test
  public void sqlOperation() {
    Properties props = new Properties();
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .sessionProperty(JDBC_CONNECTION_PROPERTIES, props)
            .build();
    Session session = ds.getSession(t -> System.out.println("ERROR: " + t.getMessage()));
    try (session) {
      assertNotNull(session);
      session.operation(TRIVIAL).submit();
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  /**
   * Execute a few trivial queries. 
   */
  @Test
  public void rowOperation() {
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> System.out.println("ERROR: " + t.getMessage()))) {
      assertNotNull(session);
      session.<Void>rowOperation(TRIVIAL)
              .collect(Collector.of(() -> null,
                                    (a, r) -> assertEquals("1", r.at(1).get(String.class)),
                                    (x, y) -> null))
              .submit();
      session.<Integer>rowOperation("select * from forum_user")
              .collect(Collector.<Result.RowColumn, int[], Integer>of(() -> new int[1],
                      (int[] a, Result.RowColumn r) -> {
                        a[0] = a[0]+r.at("total_score").get(Integer.class);
                      },
                      (l, r) -> l,
                      a -> (Integer)a[0]))
              .submit()
              .getCompletionStage()
              .thenAccept( n -> assertEquals(29025, n.intValue()));
      session.<Integer>rowOperation("select * from forum_user where id = ?")
              .set("1", 7782)
              .collect(Collector.of(
                      () -> null,
                      (a, r) -> assertEquals(2450, r.at("sal")
                                                    .get(Integer.class)
                                                    .intValue()),
                      (l, r) -> null))
              .onError(t -> fail(t.getMessage()))
              .submit();
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  /**
   * check does error handling do anything
   */
  @Test
  public void errorHandling() throws Exception {
    CountDownLatch logonErrorLatch = new CountDownLatch(1);
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url("invalid" + URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> logonErrorLatch.countDown())) {
      assertTrue(logonErrorLatch.await(getTimeout().toMillis(), 
                                       TimeUnit.MILLISECONDS));
    }
    
    CountDownLatch sqlErrorLatch = new CountDownLatch(1);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> System.out.println("ERROR: " + t.toString()))) {
      session.<Integer>rowOperation("select * from forum_user where iddd = ?")
              .set("1", 7782)
              .collect(Collector.of(
                      () -> null,
                      (a, r) -> fail("Expected error"),
                      (l, r) -> null))
              .onError( t -> sqlErrorLatch.countDown())
              .submit();
      assertTrue(sqlErrorLatch.await(getTimeout().toMillis(),
                                     TimeUnit.MILLISECONDS));
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  /**
   * Do something that approximates real work. Do a transaction. Uses
   * TransactionCompletion, CompletionStage args, and catch Operation.
   */
  @Test
  public void transaction() {
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> System.out.println("ERROR: " + t.toString()))) {
      TransactionCompletion trans = session.transactionCompletion();
      CompletionStage<Integer> idF = session.<Integer>rowOperation(
        "select id, name from forum_user where name = ? for update")
              .set("1", "OGORMAN", AdbaType.VARCHAR)
              .collect(Collector.of(
                      () -> new int[1], 
                      (a, r) -> {a[0] = r.at("id").get(Integer.class); },
                      (l, r) -> null,
                      a -> a[0])
              )
              .submit()
              .getCompletionStage();
      idF.thenAccept( id -> assertEquals(7782, id.intValue()));
      session.<Long>rowCountOperation("update user set city_id = ? where id = ?")
              .set("1", 40, AdbaType.INTEGER)
              .set("2", idF, AdbaType.INTEGER)
              .apply(c -> {
                if (1L != c.getCount()) trans.setRollbackOnly();
                return c.getCount();
              })
              .onError(t -> fail(t.getMessage()))
              .submit()
              .getCompletionStage()
              .thenAccept( c -> assertEquals(1L, c.longValue()));
      session.catchErrors();
      assertFalse(trans.isRollbackOnly());
      session.rollback();
    }    
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
}
