/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.service;

import com.foobar.appschema.domain.Customer;
import com.foobar.appschema.repo.CatalogCustomerRepository;
import com.foobar.appschema.repo.CustomerSpecification;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
public class CustomerService {
    private final CatalogCustomerRepository catalogCustomerRepository;

    @Autowired
    public CustomerService(CatalogCustomerRepository catalogCustomerRepository) {
        this.catalogCustomerRepository = catalogCustomerRepository;
    }

    @Transactional(readOnly = true, transactionManager = "catalogTransactionManager")
    public Customer getCustomer(String id) {
        return catalogCustomerRepository.findById(id).orElseThrow(() -> new RuntimeException("Customer not found"));
    }

    @Transactional(transactionManager = "catalogTransactionManager")
    public Customer saveCustomer(Customer customer) {
        return catalogCustomerRepository.save(customer);
    }

    @Transactional(readOnly = true, transactionManager = "catalogTransactionManager")
    public Customer getRandomCustomer() {
        return catalogCustomerRepository.findRandomCustomer()
                .orElseThrow(() -> new RuntimeException("Random customer not found"));
    }

    @Transactional(readOnly = true, transactionManager = "catalogTransactionManager")
    public List<Customer> searchCustomers(String name, String surname, Integer age) {
        return catalogCustomerRepository.findAll(CustomerSpecification.byDynamicFilters(name, surname, age));
    }
}
