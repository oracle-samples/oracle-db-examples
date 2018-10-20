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
import org.junit.Test;
import static org.junit.Assert.*;

public class DataSourceFactoryTest2 {

  /**
   * Verify that when DataSourceFactory name is null then it throws an
   * exception.
   */
  @Test (expected = IllegalArgumentException.class)
  public void nullDataSourceFactory() {
     DataSourceFactory.newFactory(null);
     fail("Exception expected");
  }
}
