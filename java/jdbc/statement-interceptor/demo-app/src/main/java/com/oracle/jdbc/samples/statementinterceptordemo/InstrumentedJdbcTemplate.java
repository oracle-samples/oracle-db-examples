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

import com.oracle.jdbc.samples.statementinterceptordemo.models.Statistic;
import org.springframework.dao.DataAccessException;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.ParameterizedPreparedStatementSetter;
import org.springframework.jdbc.core.RowMapper;

import javax.sql.DataSource;
import java.util.Collection;
import java.util.List;

/**
 * JdbcTemplate implementation that also keep track of time spent
 * doing JDBC calls
 * Note: we do not used Springboot actuator as setting them up
 * for our need will be too much "tasks"
 */
public class InstrumentedJdbcTemplate extends JdbcTemplate {

  private Statistic stat;

  /**
   * Creates a new <code>InstrumentedJdbcTemplate</code>
   *
   * @param dataSource the datasource used by this template
   * @param tag        the tag assigned to collected statistics.
   */
  public InstrumentedJdbcTemplate(DataSource dataSource, String tag) {
    super(dataSource);
    this.stat = Statistic.builder().tag(tag).build();
  }

  @Override
  public <T> List<T> query(String sql, RowMapper<T> rowMapper)
    throws DataAccessException {
    final long s1 = System.currentTimeMillis();
    Exception raised = null;
    try {
      return super.query(sql, rowMapper);
    } catch (Exception e) {
      raised = e;
      throw e;
    } finally {
      if (raised == null) {
        this.stat.accumulate(System.currentTimeMillis() - s1);
      }
    }

  }

  @Override
  public void execute(String sql) throws DataAccessException {
    final long s1 = System.currentTimeMillis();
    Exception raised = null;
    try {
      super.execute(sql);
    } catch (Exception e) {
      raised = e;
      throw e;
    } finally {
      if (raised == null) {
        this.stat.accumulate(System.currentTimeMillis() - s1);
      }
    }
  }

  @Override
  public <T> int[][] batchUpdate(String sql, Collection<T> batchArgs,
                                 int batchSize,
                                 ParameterizedPreparedStatementSetter<T> pss)
    throws DataAccessException {
    final long s1 = System.currentTimeMillis();
    Exception raised = null;
    try {
      return super.batchUpdate(sql, batchArgs, batchSize, pss);
    } catch (Exception e) {
      raised = e;
      throw e;
    } finally {
      if (raised == null) {
        this.stat.accumulate(System.currentTimeMillis() - s1);
      }
    }
  }

  /**
   * Gets collected statistics
   *
   * @return the statistics collected so far.
   */
  public Statistic getStatistic() {
    return this.stat;
  }

}
