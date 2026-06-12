/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.instance.controller;

import com.foobar.ShardingController;
import com.foobar.instance.domain.MetaData;
import com.foobar.instance.service.MetaDataService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/metadata")
public class MetaDataController {

  private final MetaDataService metaDataService;

  @Autowired
  public MetaDataController(MetaDataService metaDataService) {
    this.metaDataService = metaDataService;
  }

  @GetMapping("/{country}")
  public String getInstance(@PathVariable("country") String country) {
    ShardingController.getShardingKeyContext().set(country);
    MetaData instance = metaDataService.getInstance(country);
    return instance.toString() + "?\n";
  }

  @PostMapping("/{country}")
  public String postInstance(@PathVariable("country") String country) {
    ShardingController.getShardingKeyContext().set(country);
    MetaData instance = metaDataService.postInstance(country); // This uses the WriteFooRepository to save
    return instance.toString() + "!\n";
  }

}
