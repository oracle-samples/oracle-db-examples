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

import static jdk.incubator.sql2.AdbaDataSourceProperty.*;
import static org.junit.Assert.*;

import org.junit.Test;

/**
 * Verifies the public API of DataSourceProperty functions as described in the 
 * ADBA javadoc.
 */
public class DataSourcePropertyTest {
  
  @Test
  public void testMaxResources() {
    assertEquals("MAX_RESOURCES", MAX_RESOURCES.name());
    assertEquals(Integer.class, MAX_RESOURCES.range());
    assertFalse(MAX_RESOURCES.validate(true));
    assertFalse(MAX_RESOURCES.validate(-1));
    assertTrue(MAX_RESOURCES.validate(1));
    assertNotNull(MAX_RESOURCES.defaultValue());
    assertTrue(MAX_RESOURCES.validate(MAX_RESOURCES.defaultValue()));
    assertFalse(MAX_RESOURCES.isSensitive());
  }
  
  // TODO: Test the configure API
}
