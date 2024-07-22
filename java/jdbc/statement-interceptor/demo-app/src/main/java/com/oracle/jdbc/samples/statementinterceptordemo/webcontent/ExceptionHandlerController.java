package com.oracle.jdbc.samples.statementinterceptordemo.webcontent;

import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.ControllerAdvice;
import org.springframework.web.bind.annotation.ExceptionHandler;

import java.util.Arrays;
import java.util.stream.Collectors;

@ControllerAdvice
public class ExceptionHandlerController {

  @ExceptionHandler(SecurityException.class)
  public String handleException(SecurityException e, Model model) {
    final var stacktrace = Arrays.stream(e.getStackTrace())
                                 .map(StackTraceElement::toString)
                                 .collect(
                                   Collectors.joining(System.lineSeparator()));

    model.addAttribute("error", e);
    model.addAttribute("stacktrace", stacktrace);

    return "error";

  }

}
