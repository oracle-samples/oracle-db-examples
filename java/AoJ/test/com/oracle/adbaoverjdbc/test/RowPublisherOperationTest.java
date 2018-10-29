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
import java.util.concurrent.CompletionStage;
import java.util.concurrent.TimeUnit;
import org.junit.AfterClass;
import org.junit.BeforeClass;
import org.junit.Test;
import static org.junit.Assert.*;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.Flow;
import jdk.incubator.sql2.Result;
import jdk.incubator.sql2.Session;
import static com.oracle.adbaoverjdbc.test.TestConfig.*;

/**
 * This is a quick and dirty test to check if anything at all is working.
 */
public class RowPublisherOperationTest {
  
  // Define these three constants with the appropriate values for the database
  // and JDBC driver you want to use. Should work with ANY reasonably standard
  // JDBC driver. These values are passed to DriverManager.getSession.
  public static final String URL = TestConfig.getUrl();
  public static final String USER = TestConfig.getUser();
  public static final String PASSWORD = TestConfig.getPassword();

  public static final String FACTORY_NAME = 
      TestConfig.getDataSourceFactoryName();
  
  @BeforeClass
  public static void setUpClass() {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      TestFixtures.createTestSchema(se);
    }
  }

  @AfterClass
  public static void tearDownClass() {
    try (DataSource ds = getDataSource(); Session se = ds.getSession()) {
      TestFixtures.dropTestSchema(se);
    }
  }
    
  @Test
  public void rowSubscriber() throws Exception {
    System.out.println("rowSubscriber"); 
    System.out.println("============="); 

    String sql = "select id, name from forum_user";
    CompletableFuture<List<String>> result = new CompletableFuture<>();
    CompletionStage<List<String>> cs;

    Flow.Subscriber<Result.RowColumn> subscriber = getSubscriber(result, false);
            
    try (Session session = getSession()) {
            cs = session.<List<String>>rowPublisherOperation(sql)
              .subscribe(subscriber, result)
              .onError(e -> fail(e.getMessage()))
              .submit()
              .getCompletionStage();
    }

    cs.toCompletableFuture().get(getTimeout().toMillis(), 
                                 TimeUnit.MILLISECONDS);
    List<String> names = result.get(getTimeout().toMillis(), 
                                    TimeUnit.MILLISECONDS);;
    assertNotNull(names);
    assertFalse(names.isEmpty());
    assertEquals(14, names.size()); 
  }
  
  @Test
  public void slowRowSubscriberRequestOnThread() throws Exception {

    System.out.println("slowRowSubscriberRequestOnThread"); 
    System.out.println("================================"); 
    
    String sql = "select id, name from forum_user";
    CompletableFuture<List<String>> result = new CompletableFuture<>();
    CompletionStage<List<String>> cs;
    
    Flow.Subscriber<Result.RowColumn> subscriber = getSubscriber(result, true);
    
    try (Session session = getSession()) {
            cs = session.<List<String>>rowPublisherOperation(sql)
              .subscribe(subscriber, result)
              .onError(e -> e.printStackTrace())
              .timeout(getTimeout())
              .submit()
              .getCompletionStage();
    }
    
    cs.toCompletableFuture().get(getTimeout().toMillis() + 7000, 
                                 TimeUnit.MILLISECONDS);
    List<String> names = result.get(getTimeout().toMillis(),
                                    TimeUnit.MILLISECONDS);
    assertNotNull(names);
    assertFalse(names.isEmpty());
    assertEquals(14, names.size());  
  }
  
  private Session getSession() {
    return getDataSource().getSession();
  }
  
  private Flow.Subscriber<Result.RowColumn> getSubscriber(CompletableFuture<List<String>> result, boolean reqOnThread) {
    
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
  
}
