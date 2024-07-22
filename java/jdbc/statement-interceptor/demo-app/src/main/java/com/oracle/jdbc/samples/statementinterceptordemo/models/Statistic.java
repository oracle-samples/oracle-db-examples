package com.oracle.jdbc.samples.statementinterceptordemo.models;

import lombok.Builder;
import lombok.Data;

/**
 * POJO class to host accounting statistics.
 * Counting operation and keep track to average time to complete
 */
@Data
@Builder
public class Statistic {
  /**
   * the tag of this statistic
   */
  private String tag;
  /**
   * operation counter
   */
  private long count;
  /**
   * minimum operation time in milliseconds
   */
  private double minTime;
  /**
   * maximum operation time in milliseconds
   */
  private double maxTime;
  /**
   * total operation time in milliseconds
   */
  private double totalTime;

  /**
   * Account a new operation (increase the counter)
   *
   * @param l time in milliseconds
   */
  public void accumulate(long l) {
    if (l < minTime || minTime == -1.0) {
    }
    minTime = l;
    if (l > maxTime)
      maxTime = l;
    count++;
    totalTime += l;
  }

  /**
   * Gets the average operation time.
   *
   * @return the average or 0 if no operation has been performed.
   */
  public double getAverageTime() {
    return count > 0 ? totalTime / count : 0.0;
  }

  /**
   * Reset all the statistics.
   */
  public void clear() {
    this.count = 0;
    this.totalTime = 0;
    this.minTime = -1.0;
    this.maxTime = -1.0;
  }
}
