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

import com.google.gson.Gson;
import com.google.gson.reflect.TypeToken;
import com.oracle.jdbc.samples.statementinterceptordemo.models.Employee;
import com.oracle.jdbc.samples.statementinterceptordemo.models.Rule;
import com.oracle.jdbc.samples.statementinterceptordemo.services.EmployeeService;
import com.oracle.jdbc.samples.statementinterceptordemo.utils.InterceptorError;
import jakarta.servlet.http.HttpServletResponse;
import lombok.extern.java.Log;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Controller;
import org.springframework.ui.Model;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.ModelAttribute;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.servlet.view.RedirectView;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.lang.reflect.Type;
import java.util.List;
import java.util.logging.Level;
import java.util.stream.Collectors;

/**
 * main app controller
 */
@Controller
@Log
public class StatementInterceptorDemoController {

  private final EmployeeService interceptedEmployeeService;
  private final EmployeeService employeeService;

  public StatementInterceptorDemoController(
    @Qualifier("interceptedService") EmployeeService interceptedEmployeeService,
    EmployeeService service) {
    this.interceptedEmployeeService = interceptedEmployeeService;
    this.employeeService = service;

  }

  /**
   * Retrieve all setup rule in the JSON configuration file.
   *
   * @return list of rules as <code>Rule</code> instances. can be null
   */
  @ModelAttribute("allAppliedRules")
  private List<Rule> grabRules() {
    log.entering("StatementInterceptorDemoController", "grabRules");

    try {
      Gson gson = new Gson();
      Type listType = new TypeToken<List<Rule>>() {}.getType();
      List<Rule> ruleList = gson.fromJson(getStatementRulesAsJSONString(), listType);
      log.exiting("StatementInterceptorDemoController", "grabRules",ruleList);
      return ruleList;
    } catch (Exception e) {
      log.log(Level.WARNING, "error reading rules", e);
      return null;
    }
  }

  /**
   * Grabs rule configuration from JSON resource file
   * @return the JSON content
   * @throws IOException error occurred while trying to read the resource
   */
  private String getStatementRulesAsJSONString() throws IOException {
    InputStream resource =
      new ClassPathResource("demoStatementRules.json").getInputStream();
    BufferedReader reader = new BufferedReader(new InputStreamReader(resource));
    return reader.lines().collect(Collectors.joining());
  }

  @GetMapping("/")
  public RedirectView redirectToWorkshopHome(Model model) {
    return new RedirectView("demo");
  }

  @GetMapping("/demo")
  public String demo() {
    return "demohome";
  }

  @GetMapping("/userlist")
  public String userlist(
    @RequestParam(name = "q", required = false) String query,
    @RequestParam(name = "useInterceptor", defaultValue = "false")
    boolean useInterceptor, Model model, HttpServletResponse response) {

    log.finer("userlist called for query: [" + query + "]");
    log.finer("userlist called interceptor requested ? : " + useInterceptor);

    // according to flag set by user we use the simple datasource
    // or the one that have the interceptor enabled
    final var serviceToUse =
      useInterceptor ? this.interceptedEmployeeService : this.employeeService;
    List<Employee> employees = List.of();
    DynamicContentController.receivedInterceptorError = null;
    try {
      if (query == null || query.isEmpty()) {
        employees = serviceToUse.findAll();
      } else {
        employees = serviceToUse.searchByFullName(query);
      }
      response.addHeader("HX-Trigger", "operation-ended");
    } catch (SecurityException e) {
      log.log(Level.FINEST, "SecurityException exception raised", e);
      // this will wakes up HTMX listener to show exception raised
      response.addHeader("HX-Trigger", "exception-raised");
      DynamicContentController.receivedInterceptorError = new InterceptorError(e);
    }
    model.addAttribute("employees", employees);

    log.finest("normal return to view");

    return "fragments/userlist";
  }

}
