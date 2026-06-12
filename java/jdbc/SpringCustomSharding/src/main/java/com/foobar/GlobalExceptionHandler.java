/*
 * Copyright (c) 2026 Oracle and/or its affiliates.
 *
 * Licensed under the Universal Permissive License v 1.0 as shown at
 * https://oss.oracle.com/licenses/upl/
 */

package com.foobar;

import jakarta.annotation.PostConstruct;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Component;
import org.springframework.validation.FieldError;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.RequestMappingHandlerMapping;

import java.sql.SQLException;
import java.util.LinkedHashMap;
import java.util.Map;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger log = LoggerFactory.getLogger(GlobalExceptionHandler.class);

    public record ApiError(String error, String message, Map<String, String> details) {
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ApiError> handle(Exception e) {
	Throwable t = e;	
	while (t != null) {
	    log.error("{}: {}", t.getClass().getName(), t.getMessage(), t);

	    if (t instanceof SQLException sql) {
		SQLException next = sql.getNextException();

		while (next != null) {
		    log.error("NEXT: {}", next.getMessage(), next);
		    next = next.getNextException();
		}
	    }
	    t = t.getCause();
	}
	return ResponseEntity.status(500).body(new ApiError("internal_error", "Internal error", Map.of()));
    }

    
    @ExceptionHandler(RuntimeException.class)
    public ResponseEntity<ApiError> handleRuntimeException(RuntimeException ex) {
	Throwable t = ex;	
	while (t != null) {
	    log.error("{}: {}", t.getClass().getName(), t.getMessage(), t);

	    if (t instanceof SQLException sql) {
		SQLException next = sql.getNextException();

		while (next != null) {
		    log.error("NEXT: {}", next.getMessage(), next);
		    next = next.getNextException();
		}
	    }
	    t = t.getCause();
	}	
        return ResponseEntity.status(HttpStatus.NOT_FOUND)
                .body(new ApiError("not_found", ex.getMessage(), Map.of()));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ApiError> handleValidation(MethodArgumentNotValidException ex) {
        Map<String, String> details = new LinkedHashMap<>();
        for (FieldError fieldError : ex.getBindingResult().getFieldErrors()) {
            details.put(fieldError.getField(), fieldError.getDefaultMessage());
        }
        return ResponseEntity.badRequest()
                .body(new ApiError("validation_error", "Request validation failed", details));
    }

    @Component
    public static class RequestMappingLogger {

        private static final Logger logger = LoggerFactory.getLogger(RequestMappingLogger.class);

        @Qualifier("requestMappingHandlerMapping")
        @Autowired
        private RequestMappingHandlerMapping handlerMapping;

        @PostConstruct
        public void logMappings() {
            handlerMapping.getHandlerMethods().forEach((key, value) -> {
                logger.info(key + " => " + value);
            });
        }
    }
}
