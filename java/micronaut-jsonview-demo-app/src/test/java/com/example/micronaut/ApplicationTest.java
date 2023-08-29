/*
 * Copyright © 2023, Oracle and/or its affiliates.
 * 
 * Released under the Universal Permissive License v1.0 as shown at https://oss.oracle.com/licenses/upl/
 * or Apache License 2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose either license.
 */

package com.example.micronaut;

import com.example.micronaut.repository.view.StudentViewRepository;
import io.micronaut.runtime.server.EmbeddedServer;
import io.micronaut.test.extensions.junit5.annotation.MicronautTest;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

@MicronautTest
class ApplicationTest {
    @Test
    void testStartup(EmbeddedServer embeddedServer, StudentViewRepository viewRepository) {
        assertTrue(embeddedServer.isRunning());
        assertTrue(viewRepository.count() > 0);
        assertFalse(viewRepository.findAll().isEmpty());
    }
}
