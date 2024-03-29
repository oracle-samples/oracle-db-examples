package com.oracle.saga.banka.listener;

import jakarta.annotation.Priority;
import jakarta.ws.rs.Priorities;
import jakarta.ws.rs.container.ContainerRequestContext;
import jakarta.ws.rs.container.ContainerResponseContext;
import jakarta.ws.rs.container.ContainerResponseFilter;
import jakarta.ws.rs.core.MultivaluedMap;
import jakarta.ws.rs.ext.Provider;

/**
 * This filter/class is used to manage the CORS issue.
 */
@Provider
    @Priority(Priorities.HEADER_DECORATOR)
    public class AccessControlResponseFilter implements ContainerResponseFilter {

        @Override
        public void filter(ContainerRequestContext requestContext, ContainerResponseContext responseContext) {
            final MultivaluedMap<String,Object> headers = responseContext.getHeaders();

            headers.add("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS");
            headers.add("Access-Control-Allow-Origin", "*");
            if (requestContext.getMethod().equalsIgnoreCase("OPTIONS")) {
                headers.add("Access-Control-Allow-Headers", requestContext.getHeaderString("Access-Control-Request-Headers"));
            }
        }
    }
