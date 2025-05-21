/*
 * Copyright (c) 2025 Oracle, Inc.
 * Licensed under the Universal Permissive License v 1.0 as shown at https://oss.oracle.com/licenses/upl/
 */

package com.oracle.jdbc.samples.sessionlesstxns.service;

import com.oracle.jdbc.samples.sessionlesstxns.exception.PaymentFailedException;
import org.springframework.stereotype.Service;

@Service
public interface PaymentService {

  /**
   * @param sum
   * @param paymentMethodId
   * @return receipt number.
   */
  String pay(double sum, long paymentMethodId) throws PaymentFailedException;
}
