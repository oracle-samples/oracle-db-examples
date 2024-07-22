package com.oracle.jdbc.samples.statementinterceptordemo.utils;

import java.util.ArrayList;
import java.util.List;
import java.util.logging.Handler;
import java.util.logging.LogRecord;

/**
 * In memory logging handler that keep reference on 10 log records
 */
public class WebViolationHandler extends Handler {
  private final static int maxRecordCount = 10;
  private boolean closed = false;

  List<String> flattenRecords = new ArrayList<>(maxRecordCount);

  @Override
  public void publish(LogRecord record) {
    if (closed)
      throw new IllegalStateException("closed");

    if (flattenRecords.size() > maxRecordCount) {
      flattenRecords.remove(0);
    }
    StringBuffer b = new StringBuffer();
    b.append(record.getInstant().toString());
    b.append(' ');
    b.append(record.getMessage());
    if (record.getThrown() != null) {
      b.append('/');
      b.append(record.getThrown().getMessage());
    }
    flattenRecords.add(b.toString());
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
   * Gets all collected log message
   *
   * @return a list of message. can be empty not null.
   */
  public List<String> getAll() {
    return flattenRecords;
  }
}
