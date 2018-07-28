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

public class TestConfig {
  
  static final String TEST_DS_FACTORY_NAME = 
    System.getProperty("test.DATA_SOURCE_FACTORY",
      com.oracle.adbaoverjdbc.DataSourceFactory.class.getName());

  static final String TEST_USER = System.getProperty("test.USER");

  static final String TEST_PASSWORD = System.getProperty("test.PASSWORD");

  static final String TEST_URL = System.getProperty("test.URL");
}
