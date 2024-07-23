/*
 * Copyright (c) 2024, Oracle and/or its affiliates.
 *
 *   This software is dual-licensed to you under the Universal Permissive License
 *   (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
 *   2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
 *   either license.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *
 */

package com.oracle.jdbc.samples.statementinterceptordemo;

import lombok.AllArgsConstructor;
import lombok.extern.java.Log;
import oracle.ucp.jdbc.PoolDataSource;
import oracle.ucp.jdbc.PoolDataSourceFactory;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Lazy;
import org.springframework.context.annotation.Primary;
import org.springframework.context.annotation.PropertySource;
import org.springframework.core.env.Environment;
import org.springframework.core.io.ClassPathResource;
import org.springframework.core.io.Resource;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.util.ClassUtils;
import org.springframework.util.ResourceUtils;

import javax.sql.DataSource;
import java.io.BufferedReader;
import java.io.File;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.nio.file.Files;
import java.sql.SQLException;
import java.util.logging.Level;
import java.util.stream.Collectors;

@Configuration
@PropertySource("classpath:oracle-pooled-ds.properties")
@AllArgsConstructor
@Log
/**
 * Configuration class that will setup Datasources
 * For the interceptor the configuration is taken from
 * the file listed above.
 * This class export two datasource beans. One with the interceptor and another one
 * without the interceptor. These two beans will be used according to the flag
 * set by the user in the UI.
 * This class also take care of creating the JdbcTemplate instance used by the
 * application.
 */
public class TracedDataSourceConfig {

  private final Environment env;

  /**
   * Creates a UCP pool datasource
   *
   * @return the pooled datasource
   * @throws SQLException the pool cannot be created
   */
  private PoolDataSource getPoolDataSource() throws SQLException {
    PoolDataSource dataSource = PoolDataSourceFactory.getPoolDataSource();
    dataSource.setURL(env.getProperty("url"));

    dataSource.setUser(env.getProperty("username"));
    dataSource.setPassword(env.getProperty("password"));

    dataSource.setConnectionFactoryClassName(
      env.getProperty("connection-factory-class-name"));
    dataSource.setValidateConnectionOnBorrow(false);
    dataSource.setSQLForValidateConnection(
      env.getProperty("sql-for-validate-connection"));
    dataSource.setDataSourceName(env.getProperty("connection-pool-name"));
    dataSource.setInitialPoolSize(
      Integer.parseInt(env.getProperty("initial-pool-size")));
    dataSource.setMinPoolSize(
      Integer.parseInt(env.getProperty("min-pool-size")));
    dataSource.setMaxPoolSize(
      Integer.parseInt(env.getProperty("max-pool-size")));

    return dataSource;
  }

  /**
   * Create a simple pool datasource (without the interceptor).
   *
   * @return the datasource
   * @throws SQLException is the pool cannot be created.
   */
  @Bean
  @Primary
  public DataSource getDataSource() throws SQLException {
    return getPoolDataSource();
  }

  /**
   * Grabs rule configuration from JSON resource file
   * @return the JSON content
   * @throws IOException error occurred while trying to read the resource
   */
  private String getStatemenRulesAsJSONString() throws IOException {
    InputStream resource =
      new ClassPathResource("demoStatementRules.json").getInputStream();
    BufferedReader reader = new BufferedReader(new InputStreamReader(resource));
    String rules = reader.lines().collect(Collectors.joining());
    return rules;
  }

  /**
   * Create a pool datasource with the interceptor plugged in.
   *
   * @return the datasource
   * @throws SQLException is the pool cannot be created.
   */
  @Bean
  @Qualifier("interceptedDataSource")
  public DataSource getInterceptedDataSource() throws SQLException {
    PoolDataSource dataSource = getPoolDataSource();

    dataSource.setConnectionProperty("oracle.jdbc.provider.traceEventListener",
                                     "com.oracle.jdbc.samples.interceptor.SQLStatementInterceptorProvider");



    String rules;
    try {
      rules = getStatemenRulesAsJSONString();
    } catch (IOException e) {
      throw new SQLException("Failed to load rules",e);
    }
    dataSource.setConnectionProperty(
      "oracle.jdbc.provider.traceEventListener.JSONConfiguration",
      rules);
    log.fine("Loading rules from : " + rules);

    return dataSource;
  }

  /**
   * Creates a <code>JdbcTemplate</code> with accounting information.
   * This template bean is used by the datasource with the interceptor enabled.
   *
   * @return the <code>JdbcTemplate</code>
   * @throws SQLException if the underlying poll cannot be configured
   */

  @Bean
  @Qualifier("interceptedJdbcTemplate")
  public JdbcTemplate getInterceptedJdbcTemplate() throws SQLException {
    long start = System.currentTimeMillis();
    InstrumentedJdbcTemplate t = new InstrumentedJdbcTemplate(getInterceptedDataSource(), "traced");
    // be sure the pool is warm
    t.execute("SELECT 1 FROM DUAL");
    log.log(Level.INFO,"traced template init time " + (System.currentTimeMillis() - start) + "ms");
    t.getStatistic().clear();
    return t;
  }

  /**
   * Creates a <code>JdbcTemplate</code> with accounting information
   *
   * @return the <code>JdbcTemplate</code>
   * @throws SQLException if the underlying poll cannot be configured
   */
  @Bean
  @Primary
  public JdbcTemplate getJdbcTemplate() throws SQLException {
    long start = System.currentTimeMillis();
    InstrumentedJdbcTemplate t = new InstrumentedJdbcTemplate(getDataSource(), "untraced");
    // be sure the pool is warm
    t.execute("SELECT 1 FROM DUAL");
    log.log(Level.INFO,"untraced template init time " + (System.currentTimeMillis() - start) + "ms");
    t.getStatistic().clear();
    return t;

  }
}
