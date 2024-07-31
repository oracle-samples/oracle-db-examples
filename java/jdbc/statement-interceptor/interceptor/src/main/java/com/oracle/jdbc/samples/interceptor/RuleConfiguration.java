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

package com.oracle.jdbc.samples.interceptor;


import com.google.gson.JsonArray;
import com.google.gson.JsonElement;
import com.google.gson.JsonObject;
import com.google.gson.JsonParser;
import com.oracle.jdbc.samples.interceptor.rules.StatementRule;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

/**
 * Helper class to consume user configuration and instantiate defined rules.
 */
public class RuleConfiguration {
  Map<StatementRule, List<StatementViolationAction>> configurationRules;
  private static final Logger LOG = Logger.getLogger(RuleConfiguration.class.getPackageName());

  private RuleConfiguration(Map<StatementRule, List<StatementViolationAction>> rules) {
    if (rules == null)
      throw new IllegalArgumentException("cannot be null");

    this.configurationRules = rules;
  }

  /**
   * Create rule configuration form JSON array
   *
   * @param jsonContent JSON rule definition
   * @return a new configuration
   */
  public static RuleConfiguration fromJSON(final String jsonContent) throws IOException {
    Map<StatementRule, List<StatementViolationAction>> rules = new HashMap<>();
    JsonArray rulesArray = JsonParser.parseString(jsonContent).getAsJsonArray();

    for (JsonElement element : rulesArray) {
      JsonObject rule = element.getAsJsonObject();
      final String className = rule.get("className").getAsString();
      List<StatementViolationAction> definedActions = new ArrayList<>();

      try {
        // if className doesn't implement StatementRule, a ClassCastException will be thrown.
        // Or we can use raw type Class and check if it implements StatementRule using :
        // StatementRule.class.isAssignableFrom(clazz)
        Class<StatementRule> clazz = (Class<StatementRule>) Class.forName(className);

        StatementRule statementRule;
        if (rule.has("parameter"))
          statementRule = clazz.getConstructor(String.class)
                               .newInstance(rule.get("parameter").getAsString());
        else
          statementRule = clazz.getConstructor().newInstance();

        JsonArray actions = rule.get("actions").getAsJsonArray();
        for (JsonElement a : actions) {
          definedActions.add(StatementViolationAction.valueOf(a.getAsString()));
        }

        rules.put(statementRule, definedActions);
        LOG.info(clazz.getName() + " rule has been added");
      } catch (ReflectiveOperationException | ClassCastException e) {
        LOG.warning("Class " + className + " couldn't be instantiated. Cause: " + e);
      }
    }

    return new RuleConfiguration(rules);
  }


  /**
   * Create rule configuration form JSON file
   *
   * @param pathname path to the json file
   * @return a new configuration
   */
  public static RuleConfiguration fromJSONFile(String pathname) throws IOException {
    Map<StatementRule, List<StatementViolationAction>> rules = new HashMap<>();

    final String jsonString = Files.readString(Path.of(pathname));

    return fromJSON(jsonString);

  }

  /**
   * Gets all defined rules.
   *
   * @return map of defined rules. can be empty but never null.
   */
  public Map<StatementRule, List<StatementViolationAction>> getRules() {
    return configurationRules;
  }
}
