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

import static com.oracle.adbaoverjdbc.test.TestConfig.*;

/**
 * Verifies the public API of DataSource functions as described in the ADBA 
 * javadoc.
 */
public class DataSourceTest {
  
  final DataSourceFactory dsFactory = 
    DataSourceFactory.newFactory(TEST_DS_FACTORY_NAME);
  

  // Instances of this type are used to build DataSources. 
  // This type is immutable once configured. No property can be set more than once. 
  // No property can be set after build() is called.
}
