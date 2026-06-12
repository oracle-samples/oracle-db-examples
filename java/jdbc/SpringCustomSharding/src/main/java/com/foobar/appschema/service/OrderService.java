/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.service;

import com.foobar.appschema.domain.Order;
import com.foobar.appschema.domain.OrderId;
import com.foobar.appschema.repo.*;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import java.util.List;

@Service
public class OrderService {
    private final ReadOrderRepository readOrderRepository;
    private final WriteOrderRepository writeOrderRepository;

    @Autowired
    public OrderService(ReadOrderRepository readOrderRepository, WriteOrderRepository writeOrderRepository) {
        this.readOrderRepository = readOrderRepository;
        this.writeOrderRepository = writeOrderRepository;
    }

    @Transactional(readOnly = true, transactionManager = "readTransactionManager")
    public Order getOrder(OrderId id) {
        boolean b = TransactionSynchronizationManager.isCurrentTransactionReadOnly();
        String ro = TransactionSynchronizationManager.isCurrentTransactionReadOnly() ? "read" : "write";
        return readOrderRepository.findById(id).orElseThrow(() -> new RuntimeException("Order not found"));
    }

    @Transactional(transactionManager = "writeTransactionManager")
    public Order saveOrder(Order order) {
        boolean isActive = TransactionSynchronizationManager.isActualTransactionActive();
        boolean isReadOnly = TransactionSynchronizationManager.isCurrentTransactionReadOnly();
        String currentName = TransactionSynchronizationManager.getCurrentTransactionName();
        Logger logger = LoggerFactory.getLogger(getClass());
        logger.info("Transaction active: {}", isActive);
        logger.info("Transaction read-only: {}", isReadOnly);
        logger.info("Transaction name: {}", currentName);
        return writeOrderRepository.save(order);
    }

    @Transactional(readOnly = true, transactionManager = "readTransactionManager")
    public List<Order> getRandomOrder() {
        return readOrderRepository.findRandomOrder();
    }

    @Transactional(readOnly = true, transactionManager = "readTransactionManager")
    public List<Order> searchOrders(String name, String surname, Integer age) {
        // Perform search based on dynamic parameters
        return readOrderRepository.findAll(OrderSpecification.byDynamicFilters(name, surname, age));
    }
}
