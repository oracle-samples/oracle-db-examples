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

import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collector;
import jdk.incubator.sql2.Connection;
import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.DataSource;
import org.junit.Test;

public class HelloWorld {

  public static final String URL = "jdbc:derby:memory:db;create=true";
  public static final String USER = "scott";
  public static final String PASSWORD = "tiger";
  public static final String FACTORY_NAME = "com.oracle.adbaoverjdbc.DataSourceFactory";

  public static void main(String[] args) {
    DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);
    if (factory == null) {
      System.err.println("Error: Could not get a DataSourceFactory!");
    }
    else {
      System.out.println("DataSourceFactory: " + factory);
      try (DataSource ds = factory.builder()
              .url(URL)
              .username(USER)
              .password(PASSWORD)
              .build();
              Connection conn = ds.getConnection()) {
        System.out.println("Connected! DataSource: " + ds + " Connection: " + conn);
        conn.rowOperation("SELECT 1")
                .collect(Collector.of(() -> null, 
                                      (a, r) -> { System.out.println(r.at(1).get(String.class)); }, 
                                      (l, r) -> null,
                                      a -> {System.out.println("end"); return null; }))
                .onError(ex -> { ex.printStackTrace(); })
                .submit();
      }
    }
    ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
  }
  
  @Test
  public void test() {
    main(null);
  }
}
