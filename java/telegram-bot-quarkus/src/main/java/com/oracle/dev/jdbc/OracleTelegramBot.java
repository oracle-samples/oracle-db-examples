/*
  Copyright (c) 2024, Oracle and/or its affiliates.

  This software is dual-licensed to you under the Universal Permissive License
  (UPL) 1.0 as shown at https://oss.oracle.com/licenses/upl or Apache License
  2.0 as shown at http://www.apache.org/licenses/LICENSE-2.0. You may choose
  either license.

  Licensed under the Apache License, Version 2.0 (the "License");
  you may not use this file except in compliance with the License.
  You may obtain a copy of the License at

     https://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing, software
  distributed under the License is distributed on an "AS IS" BASIS,
  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
  See the License for the specific language governing permissions and
  limitations under the License.
*/

package com.oracle.dev.jdbc;

import org.eclipse.microprofile.config.inject.ConfigProperty;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;

import jakarta.annotation.PostConstruct;
import jakarta.annotation.PreDestroy;
import jakarta.enterprise.context.ApplicationScoped;
import jakarta.json.JsonObject;
import jakarta.ws.rs.client.Client;
import jakarta.ws.rs.client.ClientBuilder;
import jakarta.ws.rs.client.WebTarget;
import jakarta.ws.rs.core.Response;

@ApplicationScoped
public class OracleTelegramBot {

  private static final Logger logger = LoggerFactory
      .getLogger(OracleTelegramBot.class);

  @ConfigProperty(name = "telegram.token")
  private String token;

  @ConfigProperty(name = "telegram.chatId")
  private String chatId;

  private Client client;
  private WebTarget baseTarget;

  public void sendMessage(String message) {
    Response response = baseTarget.path("sendMessage")
        .queryParam("chat_id", chatId).queryParam("text", message).request()
        .get();
    JsonObject json = response.readEntity(JsonObject.class);
    boolean ok = json.getBoolean("ok", false);
    if (!ok) {
      logger.error("Send message failed!");
    }
  }

  @PostConstruct
  void initClient() {
    client = ClientBuilder.newClient();
    baseTarget = client.target("https://api.telegram.org/bot{token}")
        .resolveTemplate("token", this.token);
  }

  @PreDestroy
  private void closeClient() {
    client.close();
  }

}
