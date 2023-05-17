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

package oracle.jdbc.example;

import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.concurrent.Flow;

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import reactor.core.publisher.Mono;

import static org.reactivestreams.FlowAdapters.toPublisher;

/**
 * An example that uses synchronous programming to consume the results of
 * pipelined SQL.
 */
public class SynchronousExample {

  void virtualThreadsPipelineExample(OracleConnection connection) throws SQLException {

    // Prepare statements to execute
    try(
      PreparedStatement delete = connection.prepareStatement(
        "DELETE FROM example WHERE id = 1");
      PreparedStatement insert = connection.prepareStatement(
        "INSERT INTO example (id, value) VALUES (1, 'x')");
      PreparedStatement select = connection.prepareStatement(
        "SELECT id, value FROM example ORDER BY id")) {

      // Execute statements in a pipeline
      Flow.Publisher<Long> deletePublisher =
        delete.unwrap(OraclePreparedStatement.class)
          .executeUpdateAsyncOracle();
      Flow.Publisher<Long> insertPublisher =
        insert.unwrap(OraclePreparedStatement.class)
          .executeUpdateAsyncOracle();
      Flow.Publisher<OracleResultSet> selectPublisher =
        select.unwrap(OraclePreparedStatement.class)
          .executeQueryAsyncOracle();

      // Consume statement results synchronously with Project Reactor
      long deleteCount =
        Mono.from(toPublisher(deletePublisher))
          .block();
      System.out.println(deleteCount + " rows deleted");

      long insertCount =
        Mono.from(toPublisher(insertPublisher))
          .block();
      System.out.println(insertCount + " rows inserted");

      OracleResultSet resultSet =
        Mono.from(toPublisher(selectPublisher))
          .block();

      while (resultSet.next()) {
        System.out.printf(
          "id: %d, value: %s\n",
          resultSet.getLong("id"),
          resultSet.getString("value"));
      }
    }
  }
}
