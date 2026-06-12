/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.foo.controller;

import com.foobar.ShardingController;
import com.foobar.foo.domain.Foo;
import com.foobar.foo.service.FooBarService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/foobar")
public class FooBarController {

  private final FooBarService fooBarService;

  @Autowired
  public FooBarController(FooBarService fooBarService) {
    this.fooBarService = fooBarService;
  }

  @GetMapping("/{id}")
  public String fooBar(@PathVariable("id") Long id) {
    ShardingController.getShardingKeyContext().set("Denmark");
    Foo foo = fooBarService.getFoo(id);
    return foo.getFoo() + "!";
  }

  @PostMapping
  public Foo saveFoo(@RequestBody Foo foo) {
    ShardingController.getShardingKeyContext().set("Denmark");
    return fooBarService.saveFoo(foo); // This uses the WriteFooRepository to save
  }

}
