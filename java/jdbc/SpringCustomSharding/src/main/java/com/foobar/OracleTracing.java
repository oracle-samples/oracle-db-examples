/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar;

import org.slf4j.bridge.SLF4JBridgeHandler;

import java.util.logging.Handler;
import java.util.logging.Level;
import java.util.logging.Logger;

final class OracleTracing {

    private static final String[] ORACLE_LOGGERS = {
            "oracle.ucp",
            "oracle.jdbc",
            "oracle.net",
            "writeDataSource",
            "readDataSource",
            "catalogDataSource",
            "ShardDemoPool",
            "shardDemoDataSource"
    };

    private OracleTracing() {
    }

    static void enable() {
        // UCP diagnosability.
        //
        // Logging is always enabled.
        // Ring-buffer tracing is opt-in because some Oracle/UCP combinations
        // can fail while initializing the trace actor/thread.
        System.setProperty("oracle.ucp.diagnostic.enableLogging", "true");
        System.setProperty("oracle.ucp.diagnostic.loggingLevel", "FINEST");
        System.setProperty("oracle.ucp.diagnostic.bufferSize", "4096");
        System.setProperty("oracle.ucp.diagnostic.enableTrace", "true");

        // Oracle JDBC diagnosability.
        System.setProperty("oracle.jdbc.diagnostic.enableLogging", "true");
        System.setProperty("oracle.jdbc.Trace", "true");

        // Spring Boot owns the logging system and will reconfigure logging during startup.
        // Instead of relying on JUL ConsoleHandler configuration, bridge JUL into SLF4J/Logback
        // and set Oracle logger levels programmatically.
        bridgeJulToSlf4j();
        configureOracleJulLoggers();
    }

    private static void bridgeJulToSlf4j() {
        Logger rootLogger = Logger.getLogger("");
        for (Handler handler : rootLogger.getHandlers()) {
            rootLogger.removeHandler(handler);
        }
        if (!SLF4JBridgeHandler.isInstalled()) {
            SLF4JBridgeHandler.install();
        }
        rootLogger.setLevel(Level.ALL);
    }

    private static void configureOracleJulLoggers() {
        for (String loggerName : ORACLE_LOGGERS) {
            Logger.getLogger(loggerName).setLevel(Level.ALL);
        }
    }
}
