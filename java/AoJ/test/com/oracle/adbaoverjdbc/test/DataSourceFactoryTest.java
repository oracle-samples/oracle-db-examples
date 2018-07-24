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

import static com.oracle.adbaoverjdbc.test.TestConfig.*;
import static org.junit.Assert.*;
import org.junit.Test;

import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.DataSourceFactory;

/**
 * Verifies the public API of DataSourceFactory functions as described in the 
 * ADBA javadoc.
 */
public class DataSourceFactoryTest {
  
  /**
   * Assert DataSourceFactory.newFactory(String) returns null if the input
   * is not the name of a factory class.
   */
  @Test
  public void testNewFactoryNegative() {
    DataSourceFactory factory = 
      DataSourceFactory.newFactory("NOT A FACTORY NAME");
    assertNull(factory);
  }
  
  /**
   * Assert DataSourceFactory.newFactory(String) returns a DataSourceFactory
   * instance if the input is the name of a factory class.
   */
  @Test
  public void testNewFactory() {
    DataSourceFactory factory = DataSourceFactory.newFactory(TEST_DS_FACTORY_NAME);
    assertNotNull(factory);
    assertEquals(TEST_DS_FACTORY_NAME, factory.getClass().getName());
  }
  
  /**
   * Assert DataSourceFactory.builder() returns a DataSource.Builder instance.
   */
  @Test
  public void testBuilder() {
    DataSourceFactory factory = DataSourceFactory.newFactory(TEST_DS_FACTORY_NAME);
    DataSource.Builder builder = factory.builder();
    assertNotNull(builder);
  }
}
