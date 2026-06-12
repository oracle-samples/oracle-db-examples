/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebMvcConfig implements WebMvcConfigurer {

    private final ShardingKeyCleanupInterceptor shardingKeyCleanupInterceptor;

    @Autowired
    public WebMvcConfig(ShardingKeyCleanupInterceptor shardingKeyCleanupInterceptor) {
        this.shardingKeyCleanupInterceptor = shardingKeyCleanupInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(shardingKeyCleanupInterceptor);
    }
}