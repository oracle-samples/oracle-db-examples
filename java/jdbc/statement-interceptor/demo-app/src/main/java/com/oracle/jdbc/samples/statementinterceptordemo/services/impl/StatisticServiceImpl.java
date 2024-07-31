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

package com.oracle.jdbc.samples.statementinterceptordemo.services.impl;

import com.oracle.jdbc.samples.statementinterceptordemo.InstrumentedJdbcTemplate;
import com.oracle.jdbc.samples.statementinterceptordemo.models.Statistic;
import com.oracle.jdbc.samples.statementinterceptordemo.services.StatisticService;
import lombok.extern.java.Log;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Log
@Service
public class StatisticServiceImpl implements StatisticService {

  List<Statistic> allStats = new ArrayList<>();

  public StatisticServiceImpl(
    @Qualifier("interceptedJdbcTemplate") JdbcTemplate intercpetedJdbcTemplate,
    JdbcTemplate jdbcTemplate) {
    allStats.add(
      ((InstrumentedJdbcTemplate) intercpetedJdbcTemplate).getStatistic());
    allStats.add(((InstrumentedJdbcTemplate) jdbcTemplate).getStatistic());
  }

  @Override
  public Statistic getRequestStatistics(String tag) {
    return allStats.stream()
                   .filter(stat -> stat.getTag().equalsIgnoreCase(tag))
                   .findFirst()
                   .orElse(null);
  }

  @Override
  public void resetAllStatistics() {
    allStats.stream().forEach(s->{s.clear();});
  }

}
