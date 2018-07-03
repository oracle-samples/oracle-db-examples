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

import jdk.incubator.sql2.SessionProperty;
import java.util.HashMap;
import java.util.Map;

/**
 * A builder to create an AoJ session. The AoJ session creates a JDBC
 * Connection by calling {@link java.sql.DriverManager#getConnection} with the following
 * user provided SessionProperty values:
 * 
 * <dl>
 * <dt>URL</dt>
 * <dd>passed as the url argument to getSession</dd>
 * <dt>USER</dt>
 * <dd>added to the JDBC_CONNECTION_PROPERTIES as the "user" property.</dd>
 * <dt>PASSWORD</dt>
 * <dd>added to the JDBC_CONNECTION_PROPERTIES as the "password" property</dd>
 * <dt>JDBC_CONNECTION_PROPERTIES</dt>
 * <dd>a java.util.Properties passed as the info argument to getConnection</dd>
 * </dl>
 */
class SessionBuilder implements jdk.incubator.sql2.Session.Builder {

  /**
   *
   * @param ds
   * @param defaultProperties. Captured
   * @param requiredProperties. Captured
   * @return
   */
  static SessionBuilder newSessionBuilder(DataSource ds, 
          Map<SessionProperty, Object> defaultProperties,
          Map<SessionProperty, Object> requiredProperties) {
    return new SessionBuilder(ds, defaultProperties, requiredProperties);
  }

  private boolean isBuilt = false;
  private final DataSource dataSource;
  private final Map<SessionProperty, Object> defaultProperties;
  private final Map<SessionProperty, Object> requiredProperties;

  /**
   * 
   * @param ds
   * @param defaultSessionProperties
   * @param specifiedSessionProperties 
   */
  private SessionBuilder(DataSource ds,
          Map<SessionProperty, Object> defaultSessionProperties,
          Map<SessionProperty, Object> specifiedSessionProperties) {
    super();
    dataSource = ds;
    defaultProperties = new HashMap(defaultSessionProperties);
    requiredProperties = new HashMap(specifiedSessionProperties);
  }

  @Override
  public jdk.incubator.sql2.Session.Builder property(SessionProperty property, Object value) {
    if (isBuilt) {
      throw new IllegalStateException("TODO");
    }
    if (requiredProperties.containsKey(property)) {
      throw new IllegalArgumentException("cannot override required properties");
    }
    if (!property.validate(value)) {
      throw new IllegalArgumentException("TODO");
    }
    requiredProperties.put(property, value);
    return this;
  }

  @Override
  public jdk.incubator.sql2.Session build() {
    if (isBuilt) {
      throw new IllegalStateException("TODO");
    }
    isBuilt = true;
    // replace default values with specified values where provided
    // otherwise use defaults
    defaultProperties.putAll(requiredProperties);
    return Session.newSession(dataSource, defaultProperties);
  }

}
