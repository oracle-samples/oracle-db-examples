/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.foo.service;

import com.foobar.foo.domain.Foo;
import com.foobar.foo.repo.ReadFooRepository;
import com.foobar.foo.repo.WriteFooRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.transaction.support.TransactionSynchronizationManager;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

@Service
public class FooBarService {
    private final ReadFooRepository readFooRepo;
    private final WriteFooRepository writeFooRepo;

    @Autowired
    public FooBarService(ReadFooRepository fooRepo, WriteFooRepository writeFooRepo) {
        this.readFooRepo = fooRepo;
        this.writeFooRepo = writeFooRepo;
    }

    @Transactional(readOnly = true, transactionManager = "readTransactionManager")
    public Foo getFoo(Long id) {
        boolean b = TransactionSynchronizationManager.isCurrentTransactionReadOnly();
        String ro = TransactionSynchronizationManager.isCurrentTransactionReadOnly() ? "read" : "write";
        return readFooRepo.findById(id).orElseThrow(() -> new RuntimeException("Foo not found"));
    }

    @Transactional(transactionManager = "writeTransactionManager")
    public Foo saveFoo(Foo foo) {
        boolean isActive = TransactionSynchronizationManager.isActualTransactionActive();
        boolean isReadOnly = TransactionSynchronizationManager.isCurrentTransactionReadOnly();
        String currentName = TransactionSynchronizationManager.getCurrentTransactionName();
        Logger logger = LoggerFactory.getLogger(getClass());
        logger.info("Transaction active: {}", isActive);
        logger.info("Transaction read-only: {}", isReadOnly);
        logger.info("Transaction name: {}", currentName);
        return writeFooRepo.save(foo);
    }
}
