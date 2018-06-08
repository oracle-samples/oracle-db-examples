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
import java.util.HashSet;
import java.util.Map;
import java.util.Set;

/**
 * Bare bones DataSource. No support for Connection caching.
 *
 */
class DataSource implements jdk.incubator.sql2.DataSource {

  static DataSource newDataSource(Map<ConnectionProperty, Object> defaultConnectionProperties,
          Map<ConnectionProperty, Object> requiredConnectionProperties) {
    return new DataSource(defaultConnectionProperties, requiredConnectionProperties);
  }

  protected final Map<ConnectionProperty, Object> defaultConnectionProperties;
  protected final Map<ConnectionProperty, Object> requiredConnectionProperties;
  
  protected final Set<Connection> openConnections = new HashSet<>();

  protected DataSource(Map<ConnectionProperty, Object> defaultProps,
          Map<ConnectionProperty, Object> requiredProps) {
    super();
    defaultConnectionProperties = defaultProps;
    requiredConnectionProperties = requiredProps;
  }

  @Override
  public Connection.Builder builder() {
    return ConnectionBuilder.newConnectionBuilder(this, defaultConnectionProperties, requiredConnectionProperties);
  }

  @Override
  public void close() {
    openConnections.stream().forEach( c -> c.close() );
  }
  
  
  
  DataSource registerConnection(Connection c) {
    openConnections.add(c);
    return this;
  }
  
  DataSource deregisterConnection(Connection c) {
    openConnections.remove(c);
    return this;
  }

}
