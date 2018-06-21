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
package com.oracle.adbaoverjdbc;

import jdk.incubator.sql2.ConnectionProperty;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

/**
 *
 */
class DataSourceBuilder implements jdk.incubator.sql2.DataSource.Builder {

  static DataSourceBuilder newDataSourceBuilder() {
    return new DataSourceBuilder();
  }

  protected boolean isBuilt = false;
  
  /**
   * defaultConnectionProperties can be overridden by a ConnectionBuilder
   */
  Map<ConnectionProperty, Object> defaultConnectionProperties = new HashMap<>();
  
  /**
   * it is an error if a ConnectionBuilder tries to override requiredConnectionProperties
   */
  Map<ConnectionProperty, Object> requiredConnectionProperties = new HashMap<>();

  @Override
  public jdk.incubator.sql2.DataSource.Builder defaultConnectionProperty(ConnectionProperty property, Object value) {
    if (isBuilt) {
      throw new IllegalStateException("TODO");
    }
    if (defaultConnectionProperties.containsKey(property)) {
      throw new IllegalArgumentException("cannot set a default multiple times");
    }
    if (requiredConnectionProperties.containsKey(property)) {
      throw new IllegalArgumentException("cannot set a default that is already required");
    }
    if (!property.validate(value)) {
      throw new IllegalArgumentException("TODO");
    }
    defaultConnectionProperties.put(property, value);
    return this;
  }

  @Override
  public jdk.incubator.sql2.DataSource.Builder connectionProperty(ConnectionProperty property, Object value) {
    if (isBuilt) {
      throw new IllegalStateException("TODO");
    }
    if (defaultConnectionProperties.containsKey(property)) {
      throw new IllegalArgumentException("cannot set a required prop that has a default");
    }
    if (requiredConnectionProperties.containsKey(property)) {
      throw new IllegalArgumentException("cannot set a required prop multiple times");
    }
    if (!property.validate(value)) {
      throw new IllegalArgumentException("TODO");
    }
    requiredConnectionProperties.put(property, value);
    return this;
  }

  @Override
  public jdk.incubator.sql2.DataSource.Builder requestHook(Consumer<Long> request) {
    throw new UnsupportedOperationException("Not supported yet."); //To change body of generated methods, choose Tools | Templates.
  }

  @Override
  public jdk.incubator.sql2.DataSource build() {
    if (isBuilt) {
      throw new IllegalStateException("cannot build more than once. All objects are use-once");
    }
    isBuilt = true;
    return DataSource.newDataSource(defaultConnectionProperties, requiredConnectionProperties);
  }

}
