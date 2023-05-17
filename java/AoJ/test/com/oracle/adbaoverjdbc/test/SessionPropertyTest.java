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

import static jdk.incubator.sql2.AdbaSessionProperty.*;
import static org.junit.Assert.*;

import java.util.Properties;

import org.junit.Test;

import com.oracle.adbaoverjdbc.JdbcConnectionProperties;

import jdk.incubator.sql2.SessionProperty;

/**
 * Verifies the public API of SessionProperty functions as described in the 
 * ADBA javadoc.
 */
public class SessionPropertyTest {
  
  @Test
  public void testUser() {
    assertEquals("USER", USER.name());
    assertEquals(String.class, USER.range());
    assertFalse(USER.validate(1234));
    assertTrue(USER.validate("testuser"));
    assertNull(USER.defaultValue());
    assertFalse(USER.isSensitive());
  }
  
  @Test
  public void testPassword() {
    assertEquals("PASSWORD", PASSWORD.name());
    assertEquals(String.class, PASSWORD.range());
    assertFalse(PASSWORD.validate(1234));
    assertTrue(PASSWORD.validate("tiger"));
    assertNull(PASSWORD.defaultValue());
    assertTrue(PASSWORD.isSensitive());
  }
  
  @Test
  public void testJdbcConnectionProperties() {
    SessionProperty jdbcProps = 
      JdbcConnectionProperties.JDBC_CONNECTION_PROPERTIES;
    
    assertEquals("JDBC_CONNECTION_PROPERTIES", jdbcProps.name());
    assertEquals(Properties.class, jdbcProps.range());
    assertFalse(jdbcProps.validate(1234));
    assertTrue(jdbcProps.validate(new Properties()));
    assertNotNull(jdbcProps.defaultValue());
    assertTrue(jdbcProps.validate(jdbcProps.defaultValue()));
    assertFalse(jdbcProps.isSensitive());
  }
  

  @Test
  public void testSensitiveJdbcConnectionProperties() {
    SessionProperty sensitiveJdbcProps = 
      JdbcConnectionProperties.SENSITIVE_JDBC_CONNECTION_PROPERTIES;
    
    assertEquals("SENSITIVE_JDBC_CONNECTION_PROPERTIES", 
                 sensitiveJdbcProps.name());
    assertEquals(Properties.class, sensitiveJdbcProps.range());
    assertFalse(sensitiveJdbcProps.validate(1234));
    assertTrue(sensitiveJdbcProps.validate(new Properties()));
    assertNotNull(sensitiveJdbcProps.defaultValue());
    assertTrue(sensitiveJdbcProps.validate(sensitiveJdbcProps.defaultValue()));
    assertTrue(sensitiveJdbcProps.isSensitive());
  }
  
  // TODO: Test the configureOperation API
}
