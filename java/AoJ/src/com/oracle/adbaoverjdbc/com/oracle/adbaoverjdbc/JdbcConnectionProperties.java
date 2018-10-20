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

import java.util.Properties;

/**
 * An ADBA SessionProperty that specifies a set of JDBC Connection properties.
 * Its value is a java.util.Properties. This value is passed as the info argument
 * when creating a java.sql.Connection.
 * <br>
 * Two types of JdbcConnectionProperties are defined in order to distinguish 
 * {@linkplain jdk.incubator.sql2.SessionProperty#isSensitive() sensitive and non-sensitive JDBC properties.}:
 * <ul>
 * <li>
 * {@link #JDBC_CONNECTION_PROPERTIES} is appropriate for non-sensitive
 *  properties.
 * </li>
 * <li>
 * {@link #SENSITIVE_JDBC_CONNECTION_PROPERTIES} is appropriate for sensitive
 *  properties.
 * </li>
 * </ul>
 * If values for both JdbcSessionProperties have been specified for a session, 
 * and both values specify the same JDBC property, this is an illegal 
 * specification. Attempting to create a {@link Session} with this 
 * configuration will result in an {@link IllegalArgumentException}.   
 *  
 */
public enum JdbcConnectionProperties 
  implements jdk.incubator.sql2.SessionProperty {
  
  /** 
   * A SessionProperty which specifies non-sensitive JDBC Connection 
   * properties. 
   */
  JDBC_CONNECTION_PROPERTIES(false),

  /**
   * A SessionProperty which specifies sensitive JDBC Connection properties,
   * such as passwords.
   */
  SENSITIVE_JDBC_CONNECTION_PROPERTIES(true);
  
  private final boolean sensitive;
  
  private JdbcConnectionProperties(boolean sensitive) {
    this.sensitive = sensitive;
  }

  @Override
  public Class range() {
    return Properties.class;
  }

  @Override
  public Object defaultValue() {
    return new Properties();
  }

  @Override
  public boolean isSensitive() {
    return sensitive;
  }
}
