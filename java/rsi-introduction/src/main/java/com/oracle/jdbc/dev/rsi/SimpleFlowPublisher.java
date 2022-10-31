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

package com.oracle.jdbc.dev.rsi;

import java.sql.SQLException;
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import oracle.rsi.ReactiveStreamsIngestion;

public class SimpleFlowPublisher {

  public static void main(String[] args) throws SQLException {

    ExecutorService workerThreadPool = Executors.newFixedThreadPool(2);

	// Reference for JDBC URL formats at
	// https://docs.oracle.com/en/database/oracle/oracle-database/21/jajdb/
	ReactiveStreamsIngestion rsi = ReactiveStreamsIngestion.builder().url(DatabaseConfig.getJdbcConnectionUrl())
			.username(DatabaseConfig.USER).password(DatabaseConfig.PASSWORD).schema(DatabaseConfig.SCHEMA)
			.executor(workerThreadPool).bufferRows(10).bufferInterval(Duration.ofSeconds(20)).entity(Customer.class)
			.build();

    SimpleObjectPublisher<Object[]> publisher = new SimpleObjectPublisher<Object[]>();
    publisher.subscribe(rsi.subscriber());

    SimpleObjectPublisher<Object[]> anotherPublisher = new SimpleObjectPublisher<Object[]>();
    anotherPublisher.subscribe(rsi.subscriber());
    
    publisher.accept(new Object[] { 7, "John Doe", "North" });
    publisher.accept(new Object[] { 8, "Jane Doe", "North" });
    publisher.accept(new Object[] { 9, "John Smith", "South" });

    anotherPublisher.accept(new Object[] { 10, "John Doe", "North" });
    anotherPublisher.accept(new Object[] { 11, "Jane Doe", "North" });
    anotherPublisher.accept(new Object[] { 12, "John Smith", "South" });
    
    rsi.close();

    workerThreadPool.shutdown();

  }

}



