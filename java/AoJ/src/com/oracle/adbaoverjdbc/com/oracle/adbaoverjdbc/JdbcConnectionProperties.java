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
 *
 */
public class JdbcConnectionProperties implements jdk.incubator.sql2.SessionProperty {
  
  public static final JdbcConnectionProperties JDBC_CONNECTION_PROPERTIES
          = new JdbcConnectionProperties();
  
  private JdbcConnectionProperties() {
  }

  @Override
  public String name() {
    return "JDBC_SESSION_PROPERTIES";
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
    return false;
  }
  
  @Override
  public String toString() {
    return name();
  }
}
