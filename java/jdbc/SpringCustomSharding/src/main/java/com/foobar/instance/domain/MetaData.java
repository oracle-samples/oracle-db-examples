/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.instance.domain;

/**
 *  Simple model for:
 *  select host_name, VERSION_FULL,INSTANCE_NAME, (select open_mode from v$database) open_mode
 */
public class MetaData {
    String HOST_NAME;
    String VERSION_FULL;
    String INSTANCE_NAME;
    String OPEN_MODE;
    String SERVICE_NAME;

    public MetaData(String HOST_NAME, String VERSION_FULL, String INSTANCE_NAME, String OPEN_MODE, String SERVICE_NAME) {
        this.HOST_NAME = HOST_NAME;
        this.VERSION_FULL = VERSION_FULL;
        this.INSTANCE_NAME = INSTANCE_NAME;
        this.OPEN_MODE = OPEN_MODE;
        this.SERVICE_NAME = SERVICE_NAME;
    }

    public String getHOST_NAME() {
        return HOST_NAME;
    }

    public String getVERSION_FULL() {
        return VERSION_FULL;
    }

    public String getINSTANCE_NAME() {
        return INSTANCE_NAME;
    }

    public String getOPEN_MODE() {
        return OPEN_MODE;
    }

    public String getSERVICE_NAME() { return SERVICE_NAME;
    }

    @Override
    public String toString() {
        return "Instance{" +
                "HOST_NAME='" + HOST_NAME + '\'' +
                ", VERSION_FULL='" + VERSION_FULL + '\'' +
                ", INSTANCE_NAME='" + INSTANCE_NAME + '\'' +
                ", OPEN_MODE='" + OPEN_MODE + '\'' +
                ", SERVICE_NAME='" + SERVICE_NAME + '\'' +
                '}';
    }
}