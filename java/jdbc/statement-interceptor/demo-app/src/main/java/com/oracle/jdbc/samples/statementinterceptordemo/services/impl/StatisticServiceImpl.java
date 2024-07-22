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
}
