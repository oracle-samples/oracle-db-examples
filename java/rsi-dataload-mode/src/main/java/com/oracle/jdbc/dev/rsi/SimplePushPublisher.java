/*
  Copyright (c) 2024, Oracle and/or its affiliates.

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

import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

import oracle.rsi.PushPublisher;
import oracle.rsi.ReactiveStreamsIngestion;

public class SimplePushPublisher {

	public static void main(String[] args) {

		ExecutorService workerThreadPool = Executors.newFixedThreadPool(2);

		// Reference for JDBC URL formats at
		// https://docs.oracle.com/en/database/oracle/oracle-database/21/jajdb/
		ReactiveStreamsIngestion rsi = ReactiveStreamsIngestion.builder()
				.useDataLoadMode()
				.url(DatabaseConfig.getJdbcConnectionUrl())
				.username(DatabaseConfig.USER).password(DatabaseConfig.PASSWORD).schema(DatabaseConfig.SCHEMA)
				.executor(workerThreadPool).bufferRows(10).bufferInterval(Duration.ofSeconds(20)).entity(Customer.class)
				.build();

		// RSI publisher
		PushPublisher<Object[]> firstPublisher = ReactiveStreamsIngestion.pushPublisher();
		firstPublisher.subscribe(rsi.subscriber());
		firstPublisher.accept(new Object[] { RsiHelper.randomize(), "Juarez Junior", "South" });
		firstPublisher.accept(new Object[] { RsiHelper.randomize(), "Jane Melina", "North" });
		firstPublisher.accept(new Object[] { RsiHelper.randomize(), "John Gosling", "South" });

		// Another RSI publisher
		PushPublisher<Object[]> secondPublisher = ReactiveStreamsIngestion.pushPublisher();
		secondPublisher.subscribe(rsi.subscriber());
		secondPublisher.accept(new Object[] { RsiHelper.randomize(), "Gupta Folk", "North" });
		secondPublisher.accept(new Object[] { RsiHelper.randomize(), "Jack Doe", "North" });
		secondPublisher.accept(new Object[] { RsiHelper.randomize(), "Steff Cazado", "South" });

		try {
			firstPublisher.close();
			secondPublisher.close();
			rsi.close();
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			workerThreadPool.shutdown();
		}

	}

}
