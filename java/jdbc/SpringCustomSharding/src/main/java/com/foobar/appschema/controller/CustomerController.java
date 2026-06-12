/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.controller;

import com.foobar.appschema.dto.AppSchemaApiMapper;
import com.foobar.appschema.dto.CustomerRequest;
import com.foobar.appschema.dto.CustomerResponse;
import com.foobar.appschema.domain.Customer;
import com.foobar.appschema.service.CustomerService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping({"/customers"})
public class CustomerController {

  private final CustomerService customerService;

  @Autowired
  public CustomerController(CustomerService customerService) {
    this.customerService = customerService;
  }

  @GetMapping("/{id}")
  public CustomerResponse getCustomer(@PathVariable("id") String id) {
    return AppSchemaApiMapper.toCustomerResponse(customerService.getCustomer(id));
  }

  @GetMapping({"", "/search"})
  public List<CustomerResponse> searchCustomers(
          @RequestParam(value = "name", required = false) String name,
          @RequestParam(value = "surname", required = false) String surname,
          @RequestParam(value = "age", required = false) Integer age) {
    return customerService.searchCustomers(name, surname, age).stream()
            .map(AppSchemaApiMapper::toCustomerResponse)
            .toList();
  }

  @GetMapping("/random")
  public CustomerResponse getRandomCustomers() {
    return AppSchemaApiMapper.toCustomerResponse(customerService.getRandomCustomer());
  }

  @PostMapping
  public CustomerResponse saveCustomer(@Valid @RequestBody CustomerRequest customer) {
    Customer saved = customerService.saveCustomer(AppSchemaApiMapper.toCustomer(customer));
    return AppSchemaApiMapper.toCustomerResponse(saved);
  }

}
