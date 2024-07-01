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

package com.oracle.dev.jdbc;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.concurrent.ThreadLocalRandom;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import io.quarkus.scheduler.Scheduled;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.inject.Inject;
import oracle.jdbc.pool.OracleDataSource;

@ApplicationScoped
public class JDBCQueryMessenger {

  private static final Logger logger = LoggerFactory
      .getLogger(JDBCQueryMessenger.class);

  @ConfigProperty(name = "jdbc.url")
  private String jdbcUrl;

  @ConfigProperty(name = "jdbc.username")
  private String jdbcUserName;

  @ConfigProperty(name = "jdbc.password")
  private String jdbcPassword;

  @ConfigProperty(name = "jdbc.query")
  private String jdbcQuery;

  @Inject
  private OracleTelegramBot bot;

  private OracleDataSource ods;

  @Scheduled(every = "10s")
  public void sendQueryResults() {
    initDatasource();
    bot.sendMessage(query());
  }

  private String query() {
    StringBuilder queryResults = new StringBuilder();
    ResultSet rslt = null;
    try (Connection conn = ods.getConnection();
        PreparedStatement stmt = conn.prepareStatement(jdbcQuery);) {
      stmt.setInt(1, randomize());
      rslt = stmt.executeQuery();
      while (rslt.next()) {
        queryResults.append(rslt.getString("TIP"));
        logger.info(queryResults.toString());
      }
      rslt.close();
    } catch (SQLException e) {
      e.printStackTrace();
    }
    return queryResults.toString();
  }

  private void initDatasource() {
    try {
      ods = new OracleDataSource();
      ods.setURL(jdbcUrl);
      ods.setUser(jdbcUserName);
      ods.setPassword(jdbcPassword);
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }

  private int randomize() {
    return ThreadLocalRandom.current().nextInt(1, 13 + 1);
  }

}
