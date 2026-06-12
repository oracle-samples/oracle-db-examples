/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.repo;

import com.foobar.appschema.domain.Order;
import com.foobar.appschema.domain.OrderId;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.JpaSpecificationExecutor;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Optional;

@Repository
@Transactional(readOnly = true, transactionManager = "readTransactionManager")
public interface ReadOrderRepository extends JpaRepository<Order, OrderId>, JpaSpecificationExecutor<Order> {

  @Override
  Optional<Order> findById(OrderId id);

  @Query(value = "SELECT * FROM ORDERS SAMPLE BLOCK(40,100) ORDER BY DBMS_RANDOM.VALUE FETCH FIRST 1 ROWS ONLY", nativeQuery = true)
  List<Order> findRandomOrder();
}
