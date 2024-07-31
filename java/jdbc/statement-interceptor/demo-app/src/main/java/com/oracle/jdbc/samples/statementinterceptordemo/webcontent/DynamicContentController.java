/*
 * Copyright (c) 2024, Oracle and/or its affiliates.
 *
 *   This software is dual-licensed to you under the Universal Permissive License
 *   (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
 *   2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
 *   either license.
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *      https://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *
 */

package com.oracle.jdbc.samples.statementinterceptordemo.webcontent;

import com.oracle.jdbc.samples.interceptor.SQLStatementInterceptor;
import com.oracle.jdbc.samples.statementinterceptordemo.services.StatisticService;
import com.oracle.jdbc.samples.statementinterceptordemo.utils.WebViolationHandler;
import jakarta.servlet.http.HttpServletRequest;
import lombok.extern.java.Log;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.ResponseBody;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.logging.Handler;
import java.util.logging.Logger;
import java.util.stream.Collectors;

/**
 * Controllers responsible for dynamic endpoints.
 */
@RestController
@Log
public class DynamicContentController {

  // That's not correct for consurrent acces the endpoints
  // but that's enough for the sake of a demo.
  public static Exception receivedInterceptorError = null;

  private final StatisticService statService;
  private  WebViolationHandler violationHandler;
  /**
   * Creates a new controller
   *
   * @param statService the statistic service to expose stats from.
   */
  public DynamicContentController(StatisticService statService) {
    this.statService = statService;



  }

  private void grabHandler() {
    if (this.violationHandler != null)
      return;
    Handler[] handlers = Logger.getLogger(SQLStatementInterceptor.ACTION_LOGGER_NAME).getHandlers();
    for (Handler handler : handlers) {
      if (handler instanceof WebViolationHandler) {
        this.violationHandler = (WebViolationHandler) handler;
        break;
      }
    }
  }

  @GetMapping("interceptor/errors")
  public ModelAndView getSQLInterceptorErrors() {
    log.entering("DynamicContentController", "getSQLInterceptorErrors");
    // actually we known that never be null
    if (receivedInterceptorError != null) {
      final var stacktrace = Arrays.stream(receivedInterceptorError.getStackTrace())
                                   .map(StackTraceElement::toString)
                                   .collect(Collectors.joining(
                                     System.lineSeparator()));

      ModelAndView modelAndView = new ModelAndView("fragments/error");
      modelAndView.addObject("errorTitle", "SQL statement rule violation intercepted");
      modelAndView.addObject("errorMessage", receivedInterceptorError.getMessage());
      modelAndView.addObject("stacktrace", stacktrace);

      return modelAndView;
    }
    return null;
  }

  @GetMapping("interceptor/stats")
  public ModelAndView getStats() {
    ModelAndView modelAndView = new ModelAndView("fragments/demo_stats");
    modelAndView.addObject("opsStats",
                           statService.getRequestStatistics("untraced"));
    modelAndView.addObject("tracedOpsStats",
                           statService.getRequestStatistics("traced"));
    return modelAndView;
  }

  @DeleteMapping("interceptor/stats")
  public @ResponseBody ResponseEntity<String> delete() {
    statService.resetAllStatistics();
    return new ResponseEntity<String>("DELETE Response", HttpStatus.OK);
  }

  @GetMapping("interceptor/logs")
  public ModelAndView getLogs(HttpServletRequest request,
                              @RequestParam(name = "uuid", required = true) String uuid) {
    grabHandler();

    ModelAndView modelAndView = new ModelAndView("fragments/violationLogs");
    if (this.violationHandler == null) {
      modelAndView.addObject("violationHandler", new ArrayList<>());
    } else {
      modelAndView.addObject("logs", this.violationHandler.getAll(uuid));
    }
    return modelAndView;
  }

}
