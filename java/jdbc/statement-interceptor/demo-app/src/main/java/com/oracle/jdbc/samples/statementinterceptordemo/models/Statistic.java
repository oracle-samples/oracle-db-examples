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
  private double minTime = -1.0;
  /**
   * maximum operation time in milliseconds
   */
  private double maxTime = -1.0;;
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
      minTime = l;
    }
    if (l > maxTime) {
      maxTime = l;
    }
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
