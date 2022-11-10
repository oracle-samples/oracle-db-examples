/*
  Copyright (c) 2021, 2022, Oracle and/or its affiliates.
  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.
  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at
     https://www.apache.org/licenses/LICENSE-2.0
  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/
package rsi.example.common;

import oracle.rsi.ReactiveStreamsIngestion;

import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

/**
 * A class that builds RSI service.
 */
public final class RSIService {

  /** ExecutorService that uses virtual threads from JDK 19 **/
  private ExecutorService workers;

  private ReactiveStreamsIngestion rsi;

  /** URL of the target database **/
  private String url;
  /** Username of the database user **/
  private String username;
  /** Password of the database user **/
  private String password;
  /** Database schema to be used **/
  private String schema;
  /** Reference to a POJO class that represents objects in the database **/
  private Class<?> entity;

  /**
   * Start RSI
   * @return {@link oracle.rsi.ReactiveStreamsIngestion} object
   */
  public ReactiveStreamsIngestion start() {
    if (rsi != null) {
      return rsi;
    }

    workers = Executors.newVirtualThreadPerTaskExecutor();

    rsi =  ReactiveStreamsIngestion
        .builder()
        .url(url)
        .username(username)
        .password(password)
        .schema(schema)
        .entity(entity)
        .executor(workers)
        .bufferInterval(Duration.ofMinutes(60))
        .build();

    return rsi;
  }

  /**
   * Stop RSI
   */
  public void stop() {
    if (rsi != null) {
      rsi.close();
    }

    if (workers != null) {
      workers.shutdown();
    }
  }

  /**
   * Set URL
   * @param url URL of the target database.
   */
  public void setUrl(String url) {
    this.url = url;
  }

  /**
   * @param username Username of the database user
   */
  public void setUsername(String username) {
    this.username = username;
  }

  /**
   * @param password Password of the database user
   */
  public void setPassword(String password) {
    this.password = password;
  }

  /**
   * @param schema Schema to be used
   */
  public void setSchema(String schema) {
    this.schema = schema;
  }

  /**
   * @param entity A POJO class that represents objects in the database
   */
  public void setEntity(Class<?> entity) {
    this.entity = entity;
  }
}
