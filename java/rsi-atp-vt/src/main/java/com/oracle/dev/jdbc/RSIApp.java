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

package com.oracle.dev.jdbc;

import java.sql.SQLException;
import java.time.Duration;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.ThreadLocalRandom;
import java.util.stream.IntStream;

import oracle.rsi.PushPublisher;
import oracle.rsi.ReactiveStreamsIngestion;

public class RSIApp {

	private ExecutorService workerThreadPool;
	private ReactiveStreamsIngestion rsi;
	private PushPublisher<Object[]> publisher;

	public static void main(String[] args) throws SQLException {
		RSIApp app = new RSIApp();
		app.init();
		app.publish();
	}

	private void init() {
		// virtual threads
		workerThreadPool = Executors.newVirtualThreadPerTaskExecutor();
		rsi = ReactiveStreamsIngestion.builder().url(DatabaseConfig.getDbUrl()).username(DatabaseConfig.getDbUser())
				.password(DatabaseConfig.getDbPassword()).schema(DatabaseConfig.getDbSchema())
				.executor(workerThreadPool).bufferRows(200).bufferInterval(Duration.ofSeconds(20))
				.entity(Customer.class).build();
	}

	private void publish() {
		publisher = ReactiveStreamsIngestion.pushPublisher();
		publisher.subscribe(rsi.subscriber());
		// virtual threads
		var threads = IntStream.range(0, 150).mapToObj(i -> Thread.startVirtualThread(() -> {
			publisher.accept(new Object[] { ThreadLocalRandom.current().nextLong(), "Duke Java", "West" });
		})).toList();

		for (var thread : threads) {
			try {
				thread.join();
			} catch (InterruptedException e) {
				e.printStackTrace();
			}
		}
		destroy();
	}

	private void destroy() {
		try {
			publisher.close();
			rsi.close();
		} catch (Exception e) {
			e.printStackTrace();
		} finally {
			workerThreadPool.shutdown();
		}
	}

}
