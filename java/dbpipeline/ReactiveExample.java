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

import oracle.jdbc.OracleConnection;
import oracle.jdbc.OraclePreparedStatement;
import oracle.jdbc.OracleResultSet;
import org.reactivestreams.FlowAdapters;
import org.reactivestreams.Publisher;
import reactor.core.publisher.Flux;
import reactor.core.publisher.Mono;

import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.concurrent.CompletionException;
import java.util.concurrent.Flow;

/**
 * An example that uses reactive programming to consume the results of pipelined
 * SQL.
 */
public class ReactiveExample {

  void reactivePipelineExample(OracleConnection connection) throws SQLException {

    // Push a DELETE into the pipeline
    Mono.using(
        () -> connection.prepareStatement("DELETE FROM example WHERE id = 1"),
        preparedStatement -> Mono.from(publishUpdate(preparedStatement)),
        preparedStatement -> close(preparedStatement))
      .subscribe(deleteCount ->
        System.out.println(deleteCount + " rows deleted"));

    // Push an INSERT into the pipeline
    Mono.using(
        () -> connection.prepareStatement(
          "INSERT INTO example (id, value) VALUES (1, 'x')"),
        preparedStatement -> Mono.from(publishUpdate(preparedStatement)),
        preparedStatement -> close(preparedStatement))
      .subscribe(insertCount ->
        System.out.println(insertCount + " rows inserted"));

    // Push a SELECT into the pipeline
    Flux.using(
        () -> connection.prepareStatement(
          "SELECT id, value FROM example ORDER BY id"),
        preparedStatement ->
          Mono.from(publishQuery(preparedStatement))
            .flatMapMany(resultSet -> publishRows(resultSet)),
        preparedStatement -> close(preparedStatement))
      .subscribe(rowString ->
        System.out.println(rowString));
  }

  Publisher<Long> publishUpdate(PreparedStatement preparedStatement) {
    try {
      Flow.Publisher<Long> updatePublisher =
        preparedStatement.unwrap(OraclePreparedStatement.class)
          .executeUpdateAsyncOracle();

      return FlowAdapters.toPublisher(updatePublisher);
    }
    catch (SQLException sqlException) {
      return Mono.error(sqlException);
    }
  }

  Publisher<OracleResultSet> publishQuery(PreparedStatement preparedStatement) {
    try {
      Flow.Publisher<OracleResultSet> queryPublisher =
        preparedStatement.unwrap(OraclePreparedStatement.class)
          .executeQueryAsyncOracle();

      return FlowAdapters.toPublisher(queryPublisher);
    }
    catch (SQLException sqlException) {
      return Mono.error(sqlException);
    }
  }

  Publisher<String> publishRows(ResultSet resultSet) {
    try {
      Flow.Publisher<String> rowPublisher =
        resultSet.unwrap(OracleResultSet.class)
          .publisherOracle(row -> {
            try {
              return String.format("id: %d, value: %s\n",
                row.getObject("id", Long.class),
                row.getObject("value", String.class));
            }
            catch (SQLException sqlException) {
              throw new CompletionException(sqlException);
            }
          });

      return FlowAdapters.toPublisher(rowPublisher);
    }
    catch (SQLException sqlException) {
      return Flux.error(sqlException);
    }
  }

  void close(PreparedStatement preparedStatement) {
    try {
      preparedStatement.close();
    }
    catch (SQLException sqlException) {
      throw new RuntimeException(sqlException);
    }
  }

}
