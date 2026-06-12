/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.foo.repo;

import com.foobar.foo.domain.Foo;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Repository
@Transactional(transactionManager = "writeTransactionManager")
public interface WriteFooRepository extends JpaRepository<Foo, Long> {

    Optional<Foo> findById(Long id); // Same method as in ReadFooRepository
}
