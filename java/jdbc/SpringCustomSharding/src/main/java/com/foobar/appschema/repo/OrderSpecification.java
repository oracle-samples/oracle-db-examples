/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar.appschema.repo;

import com.foobar.appschema.domain.Order;
import jakarta.persistence.criteria.Predicate;
import org.springframework.data.jpa.domain.Specification;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class OrderSpecification {

    public static Specification<Order> byDynamicFilters(String name, String surname, Integer age) {
        return (root, query, criteriaBuilder) -> {
            List<Predicate> predicates = new ArrayList<>();

            if (name != null && !name.isEmpty()) {
                predicates.add(criteriaBuilder.like(root.get("firstname"), "%" + name + "%"));
            }
            if (surname != null && !surname.isEmpty()) {
                predicates.add(criteriaBuilder.like(root.get("lastname"), "%" + surname + "%"));
            }
            if (age != null) {
                predicates.add(criteriaBuilder.equal(root.get("age"), age));
            }

            return criteriaBuilder.and(predicates.toArray(new Predicate[0]));
        };
    }
}
