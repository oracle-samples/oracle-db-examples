package com.oracle.jdbc.samples.interceptor.rules;

import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class TokenStatementRuleTest {

    @Test
    void construct() {
        try {
            new TokenStatementRule(null);
            assertTrue(false,"Should have thrown IllegalArgumentException for null");
        } catch (IllegalArgumentException e) {

        }
        try {
            new TokenStatementRule("");
            assertTrue(false,"Should have thrown IllegalArgumentException for empty string");
        } catch (IllegalArgumentException e) {

        }

    }
    @Test
    void matches() {
        StatementRule  rule = new TokenStatementRule("Foo");
        assertTrue(rule.matches("this is Foo"));
        assertFalse(rule.matches("this is Bar"));
    }
}
