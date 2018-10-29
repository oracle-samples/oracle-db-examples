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

import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.DataSource;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collector;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.ArrayList;
import java.util.List;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.TransactionCompletion;

/**
 * This is a quick and dirty test to check if anything at all is working.
 */
public class ArrayRowCountOperationTest {
  
  // Define these three constants with the appropriate values for the database
  // and JDBC driver you want to use. Should work with ANY reasonably standard
  // JDBC driver. These values are passed to DriverManager.getSession.
  public static final String URL = TestConfig.getUrl();
  public static final String USER = TestConfig.getUser();
  public static final String PASSWORD = TestConfig.getPassword();
  
  public static final String FACTORY_NAME = 
    TestConfig.getDataSourceFactoryName();

  public ArrayRowCountOperationTest() {
  }

  @BeforeClass
  public static void setUpClass() throws Exception {
    try (DataSource ds = DataSourceFactory.newFactory(FACTORY_NAME)
                           .builder()
                           .url(URL)
                           .username(USER)
                           .password(PASSWORD)
                           .build();
         Session se = ds.getSession()) {
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
      TestFixtures.dropTestSchema(se);
    }
  }
  
  /**
   * Do something that approximates real work. Do a transaction. Uses
   * TransactionCompletion, CompletionStage args, and catch Operation.
   */
  @Test
  public void transaction() throws Exception {
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    try (DataSource ds = factory.builder()
            .url(URL)
            .username(USER)
            .password(PASSWORD)
            .build();
            Session session = ds.getSession(t -> System.out.println("ERROR: " + t.toString()))) {
      List<Integer> userList = new ArrayList<Integer>();
      userList.add(100);
      userList.add(101);
      userList.add(102);

      List<Integer> cityList = new ArrayList<Integer>();
      cityList.add(30);
      cityList.add(40);
      cityList.add(10);
      
//public <A, S extends T> ArrayRowCountOperation<T> collect(Collector<? super Result.RowCount, A, S> c);      

      session.<Long>arrayRowCountOperation(
        "insert into forum_user(id, city_id) values (?, ?)")
              .set("1", userList)
              .set("2", cityList)
              .collect(Collector.of(
                      () -> null,
                      (a, r) -> assertEquals(1L, r.getCount()),
                      (l, r) -> null))
              .onError(t -> fail(t.getMessage()))
              .submit()
              .getCompletionStage();
      session.catchErrors();
      session.rollback()
        .toCompletableFuture()
        .get(TestConfig.getTimeout().toMillis(), TimeUnit.MILLISECONDS);
    }    
  }
}
