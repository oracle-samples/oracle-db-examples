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

import jdk.incubator.sql2.AdbaDataSourceProperty;
import jdk.incubator.sql2.AdbaSessionProperty;
import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.DataSource.Builder;
import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.Session.Validation;
import jdk.incubator.sql2.SessionProperty;

import org.junit.Test;

import static com.oracle.adbaoverjdbc.JdbcConnectionProperties.*;
import static com.oracle.adbaoverjdbc.test.TestConfig.*;
import static org.junit.Assert.*;

import java.util.ArrayList;
import java.util.Map;
import java.util.Properties;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.CompletionException;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicReference;

/**
 * Verifies the public API of DataSource functions as described in the ADBA 
 * javadoc.
 * <br>
 * TODO:
 * 1. Verify all types of AdbaDataSourceProperty are supported.
 * 2. Verify SQL translation APIs are supported.
 */
public class DataSourceTest {
  
  final DataSourceFactory dsFactory = 
    DataSourceFactory.newFactory(getDataSourceFactoryName());

  @Test
  public void testBuild() {
    try (DataSource ds = dsFactory.builder()
           .url(getUrl())
           .username(getUser())
           .password(getPassword())
           .build()) {
      assertNotNull(ds);
    }
  }
  
  @Test (expected = IllegalStateException.class)
  public void testDoubleBuild() {
    Builder bldr = dsFactory.builder();
    try (DataSource ds = bldr.build()) { }
    try (DataSource ds = bldr.build()) { }
  }
  
  @Test
  public void testGetSession() throws Exception {
    String url = getUrl();
    String user = getUser();
    String password = getPassword();
    
    try (DataSource ds = dsFactory.builder()
           .url(url).username(user).password(password).build()) {
      
      try (Session session = ds.getSession()) {
        session.validationOperation(Validation.COMPLETE)
        .timeout(getTimeout()).submit().getCompletionStage()
        .toCompletableFuture().get();
        
        Map<SessionProperty, Object> sProps = session.getProperties();
        assertEquals(url, sProps.get(AdbaSessionProperty.URL));
        assertEquals(user, sProps.get(AdbaSessionProperty.USER));
        assertNull(sProps.get(AdbaSessionProperty.PASSWORD));
      }
    }
  }

  @Test
  public void testGetSessionWithJdbcProperties() throws Exception {
    String url = getUrl();
    String user = getUser();
    String password = getPassword();
    
    Properties jdbcProperties = new Properties();
    jdbcProperties.setProperty("user", user);
    Properties sensitiveProperties = new Properties();
    sensitiveProperties.setProperty("password", password);
    
    try (DataSource ds = dsFactory.builder().url(url)
      .sessionProperty(JDBC_CONNECTION_PROPERTIES, jdbcProperties)
      .sessionProperty(SENSITIVE_JDBC_CONNECTION_PROPERTIES, sensitiveProperties)
      .build()) {
      
      try (Session session = ds.getSession()) {
        session.validationOperation(Validation.COMPLETE).timeout(getTimeout())
          .submit().getCompletionStage().toCompletableFuture().get();
        
        Map<SessionProperty, Object> sProps = session.getProperties();
        assertEquals(url, sProps.get(AdbaSessionProperty.URL));
        assertNull(sProps.get(AdbaSessionProperty.PASSWORD));
        assertEquals(jdbcProperties, sProps.get(JDBC_CONNECTION_PROPERTIES));
        assertNull(sProps.get(SENSITIVE_JDBC_CONNECTION_PROPERTIES));
      }
    }
  }
  
  @Test
  public void testRegisterSessionProperty() {
    
    
    final ArrayList<String> userVal = new ArrayList<>();
    userVal.add("FIRST");
    
    // A user defined property where range() returns a Cloneable class.
    SessionProperty userProp = new SessionProperty() {
      private static final long serialVersionUID = 1L;
    
      @Override
      public String name() { return "USER_LIST"; }
      @Override
      public Class<?> range() { return ArrayList.class; }
      @Override
      public Object defaultValue() { return userVal; }
      @Override
      public boolean isSensitive() { return false; }
    };
    
    // A user defined property where isSensitive() returns true.
    SessionProperty sensitiveProp = new SessionProperty() {
      private static final long serialVersionUID = 1L;
      
      @Override
      public String name() { return "SECRET"; }
      @Override
      public Class<?> range() { return String.class; }
      @Override
      public Object defaultValue() { return "A secret"; }
      @Override
      public boolean isSensitive() { return true; }
    };
    
    try (DataSource ds = dsFactory.builder()
           .url(getUrl())
           .username(getUser())
           .password(getPassword())
           .registerSessionProperty(userProp)
           .registerSessionProperty(sensitiveProp)
           .build()) {
      assertNotNull(ds);
      
      try (Session se = ds.getSession()) {
        Object out1 = se.getProperties().get(userProp);
        assertEquals(userVal, out1);

        // Verify that the user's input was cloned
        userVal.add("SECOND");
        Object out2 = se.getProperties().get(userProp);
        assertNotNull(out2);
        assertTrue(out2 instanceof ArrayList);
        assertNotEquals(userVal, out2);
        assertEquals(out1, out2);
        
        // Verify the sensitive property is not exposed
        assertNull(se.getProperties().get(sensitiveProp));
      }
    }
  }
  

  @Test
  public void testGetSessionError() throws Exception {
    // Use an invalid URL to get an error message
    String url = "jdbc:oracle:not_thin:localhost:5521";
    String user = getUser();
    String password = getPassword();

    try (DataSource ds =
      dsFactory.builder().url(url).username(user).password(password).build()) {

      AtomicReference<Throwable> errConsumer = new AtomicReference<>();
      ExecutionException validEx = null;
      try (Session session = ds.getSession(errConsumer::set)) {
        session.validationOperation(Validation.COMPLETE)
          .timeout(getTimeout()).submit().getCompletionStage()
          .toCompletableFuture().get();
      } catch (ExecutionException exeEx) {
        // Expecting exceptional completion of the validation operation
        validEx = exeEx;
      }
      
      // Verify that the errConsumer was invoked, and that the validation
      // operation completed with the same error.
      Throwable attachEx = errConsumer.get();
      assertTrue(attachEx instanceof CompletionException);
      assertNotNull(validEx);
      
      // TODO: If attach operation fails, should the validation operation 
      // complete with SqlSkipped?
      // assertTrue(validEx.getCause() instanceof SqlSkippedException);
      // assertEquals(attachEx.getCause(), validEx.getCause().getCause());
      assertEquals(attachEx.getCause(), validEx.getCause());
    }
  }
  
  @Test (expected = IllegalArgumentException.class)
  public void testSessionProperty() throws Exception {
    try (DataSource ds = dsFactory.builder()
           .sessionProperty(JDBC_CONNECTION_PROPERTIES, new Properties())
           .build()) {
      ds.builder().property(JDBC_CONNECTION_PROPERTIES, new Properties());
    }
  }

  @Test (expected = IllegalArgumentException.class)
  public void testDoubleProperty() throws Exception {
    try (DataSource ds = dsFactory.builder()
           .property(AdbaDataSourceProperty.MAX_IDLE_RESOURCES, 1)
           .property(AdbaDataSourceProperty.MAX_IDLE_RESOURCES, 1)
           .build()) { }
  }
  
  @Test (expected = IllegalArgumentException.class)
  public void testDoubleSessionProperty() throws Exception {
    try (DataSource ds = dsFactory.builder()
           .sessionProperty(JDBC_CONNECTION_PROPERTIES, new Properties())
           .sessionProperty(JDBC_CONNECTION_PROPERTIES, new Properties())
           .build()) { }
  }

  @Test (expected = IllegalArgumentException.class)
  public void testDoubleDefaultProperty() throws Exception {
    try (DataSource ds = dsFactory.builder()
           .defaultSessionProperty(JDBC_CONNECTION_PROPERTIES, new Properties())
           .defaultSessionProperty(JDBC_CONNECTION_PROPERTIES, new Properties())
           .build()) { }
  }

  @Test (expected = IllegalStateException.class)
  public void testPostBuildProperty() throws Exception {
    DataSource.Builder bldr = dsFactory.builder();
    try (DataSource ds = bldr.build()) { }
    bldr.property(AdbaDataSourceProperty.MAX_IDLE_RESOURCES, 1);
  }
  
  @Test (expected = IllegalStateException.class)
  public void testPostBuildSessionProperty() throws Exception {
    DataSource.Builder bldr = dsFactory.builder();
    try (DataSource ds = bldr.build()) { }
    bldr.defaultSessionProperty(JDBC_CONNECTION_PROPERTIES, new Properties());
  }

  @Test (expected = IllegalStateException.class)
  public void testPostBuildDefaultProperty() throws Exception {
    DataSource.Builder bldr = dsFactory.builder();
    try (DataSource ds = bldr.build()) { }
    bldr.defaultSessionProperty(JDBC_CONNECTION_PROPERTIES, new Properties());
  }
  
  @Test (expected = UnsupportedOperationException.class)
  public void testRequestHook() throws Exception {
    CompletableFuture<Long> hook = new CompletableFuture<>();
    long demand;
    
    try (DataSource ds = dsFactory.builder().requestHook(hook::complete)
           .url(getUrl()).username(getUser()).password(getPassword())
           .build()) {
      // Await demand...
      demand = hook.get(getTimeout().toMillis(), TimeUnit.MILLISECONDS);
      assertTrue(demand > 0);
      // TODO: Verify IllegalStateException is thrown when demand is exceeded.
      // Consider how to write that test code. It must produce consistent 
      // results, and consume minimal resources.
    }
  }
  
  @Test (expected = IllegalArgumentException.class)
  public void testGetSessionNonDistinctJdbcProperties() throws Exception {
    String url = getUrl();
    String user = getUser();
    String password = getPassword();
    
    // Define password in both Properties
    Properties jdbcProperties = new Properties();
    jdbcProperties.setProperty("user", user);
    jdbcProperties.setProperty("password", password);
    Properties sensitiveProperties = new Properties();
    sensitiveProperties.setProperty("password", password);
    
    try (DataSource ds = dsFactory.builder().url(url)
      .sessionProperty(JDBC_CONNECTION_PROPERTIES, jdbcProperties)
      .sessionProperty(SENSITIVE_JDBC_CONNECTION_PROPERTIES, sensitiveProperties)
      .build()) {
      
      try (Session session = ds.getSession()) { }
    }
  }
}
