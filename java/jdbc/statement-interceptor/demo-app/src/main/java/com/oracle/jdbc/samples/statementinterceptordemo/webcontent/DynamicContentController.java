package com.oracle.jdbc.samples.statementinterceptordemo.webcontent;

import com.oracle.jdbc.samples.interceptor.SQLStatementInterceptor;
import com.oracle.jdbc.samples.statementinterceptordemo.services.StatisticService;
import com.oracle.jdbc.samples.statementinterceptordemo.utils.WebViolationHandler;
import lombok.extern.java.Log;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.ModelAndView;

import java.util.AbstractMap;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.logging.Handler;
import java.util.logging.Logger;
import java.util.stream.Collectors;

/**
 * Controllers responsible for dynamic endpoints.
 */
@RestController
@Log
public class DynamicContentController {

  public static Exception receivedException = null;

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

  @GetMapping("/interceptor/errors")
  public ModelAndView errors() {
    log.entering("DynamicContentController", "errors");
    // actually we known that never be null
    if (receivedException != null) {
      final var stacktrace = Arrays.stream(receivedException.getStackTrace())
                                   .map(StackTraceElement::toString)
                                   .collect(Collectors.joining(
                                     System.lineSeparator()));

      ModelAndView modelAndView = new ModelAndView("fragments/error");
      modelAndView.addObject("errorMessage", receivedException.getMessage());
      modelAndView.addObject("stacktrace", stacktrace);

      return modelAndView;
    }
    return null;
  }

  @GetMapping("/interceptor/stats")
  public ModelAndView getStats() {
    ModelAndView modelAndView = new ModelAndView("fragments/demo_stats");
    modelAndView.addObject("opsStats",
                           statService.getRequestStatistics("untraced"));
    modelAndView.addObject("tracedOpsStats",
                           statService.getRequestStatistics("traced"));
    return modelAndView;
  }

  @GetMapping("/interceptor/logs")
  public ModelAndView getLogs() {
    grabHandler();
    ModelAndView modelAndView = new ModelAndView("fragments/violationLogs");
    if (this.violationHandler == null) {
      modelAndView.addObject("violationHandler", new ArrayList<>());
    } else {
      modelAndView.addObject("logs", this.violationHandler.getAll());
    }
    return modelAndView;
  }

}
