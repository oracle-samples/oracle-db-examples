/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar;

/*
 * This class uses a thread-local variable to pass sharding key information from
 * application to UCP. The application code sets the value of sharding key on
 * the thread-local object, which is being read by UCP’s overridden
 * getConnection() method.
 */
public class ShardingController {
    private static final ThreadLocal<String> shardingKeyContext = new ThreadLocal<>();

    public static ThreadLocal<String> getShardingKeyContext() {
        return shardingKeyContext;
    }

    public static void clear() {
        shardingKeyContext.remove();
    }
}
