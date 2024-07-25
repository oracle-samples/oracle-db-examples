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

package com.oracle.jdbc.samples.statementinterceptordemo.utils;

import org.springframework.web.context.request.RequestAttributes;
import org.springframework.web.context.request.RequestContextHolder;

import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Handler;
import java.util.logging.LogRecord;

/**
 * In memory logging handler that keep reference on 10 log records.
 * Records are organized as a map. The key of this map can be a unique request client
 * identifier.
 * For safety reason it will kep up to 50 different keys.
 */
public class WebViolationHandler extends Handler {
  private final static int maxRecordCount = 10;
  private final static int maxKeyCount = 50;
  private boolean closed = false;

  Map<String, List<String>> flattenRecords = new HashMap<>(maxKeyCount);

  @Override
  public void publish(LogRecord record) {
    if (closed)
      throw new IllegalStateException("closed");


    String clientUuid = (String)RequestContextHolder.currentRequestAttributes().getAttribute("demo.client.uid",
                                                                 RequestAttributes.SCOPE_REQUEST);

    List<String> recordForClient = flattenRecords.get(clientUuid);
    if (recordForClient == null) {
      if (flattenRecords.size() > maxKeyCount) {
        // as a dummy garbage collection, just drop the first one
        flattenRecords.remove(flattenRecords.keySet().iterator().next());
      }
      recordForClient = new ArrayList<>(maxRecordCount);
      flattenRecords.put(clientUuid, recordForClient);
    }

    if (recordForClient.size() > maxRecordCount) {
      recordForClient.remove(0);
    }

    recordForClient.add(computeRecordMessage(record));
  }

  private String computeRecordMessage(LogRecord record) {
    StringBuffer b = new StringBuffer();
    b.append(record.getInstant().toString());
    b.append(' ');
    b.append(record.getMessage());
    if (record.getThrown() != null) {
      b.append('/');
      b.append(record.getThrown().getMessage());
    }
    return b.toString();
  }

  @Override
  public void flush() {
    flattenRecords.clear();
  }

  @Override
  public void close() throws SecurityException {
    flattenRecords.clear();
    closed = true;
  }

  /**
   * Gets all collected log messages.
   * @param key the key log messages belong to. if null, return all.
   * @return a list of message. can be empty not null.
   */
  public List<String> getAll(String key) {
    return flattenRecords.containsKey(key)? flattenRecords.get(key):
           Collections.EMPTY_LIST;
  }
}
