/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.util;

public class Util {
  public static String byteArrayToHex(byte[] a) {
    if (a == null) return null;

    StringBuilder sb = new StringBuilder(a.length * 2);
    for(byte b: a)
      sb.append(String.format("%02x", b));
    return sb.toString().toUpperCase();
  }

  public static byte[] hexToByteArray(String s) {
    int size = s.length();
    if (size % 2 != 0) {
      throw new IllegalArgumentException("String must have an even number of characters");
    }

    byte[] array = new byte[size / 2];
    for (int i = 0; i < size; i += 2) {
      array[i / 2] = (byte) ((Character.digit(s.charAt(i), 16) << 4) + Character.digit(s.charAt(i+1), 16));
    }

    return array;
  }
}
