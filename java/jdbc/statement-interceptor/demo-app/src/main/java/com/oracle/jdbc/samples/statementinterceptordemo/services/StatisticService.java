package com.oracle.jdbc.samples.statementinterceptordemo.services;

import com.oracle.jdbc.samples.statementinterceptordemo.models.Statistic;

/**
 * Service to expose accounting statistics.
 * Statistic POJO are referenced by their <code>String</code> tag.
 */
public interface StatisticService {
  /**
   * Gets Statistic by tag.
   *
   * @param tag the tag of the statistic to be returned
   * @return the statistic or null if no such statistic for this tag is found
   */
  Statistic getRequestStatistics(String tag);
}
