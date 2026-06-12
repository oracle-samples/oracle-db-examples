/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.foo.repo;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import org.springframework.transaction.annotation.Transactional;
import com.foobar.foo.domain.Foo;
import java.util.Optional;

@Repository
@Transactional(readOnly = true, transactionManager = "readTransactionManager")
public interface ReadFooRepository extends JpaRepository<Foo, Long> {

  @Override
  Optional<Foo> findById(Long id);
}
