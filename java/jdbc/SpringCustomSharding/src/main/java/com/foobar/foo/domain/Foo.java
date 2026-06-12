/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.foo.domain;

import jakarta.persistence.*;

@Entity
@Table(name = "foo")
public class Foo {

  @Id
  @GeneratedValue(strategy = GenerationType.SEQUENCE, generator="foo_id_seq")
  @SequenceGenerator(name="foo_id_seq", sequenceName="foo_id_seq", allocationSize=1)
  @Column(name = "ID")
  private Long id;

  @Column(name = "FOO")
  private String foo;

  Foo(String foo) {
    this.foo = foo;
  }

  public Foo() {
    // Default constructor needed by JPA
  }

  public String getFoo() {
    return foo;
  }

  @Override
  public String toString() {
    return "Foo{" +
            "id=" + id +
            ", foo='" + foo + '\'' +
            '}';
  }

}
