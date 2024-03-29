/* Copyright (c) 2021, 2022, Oracle and/or its affiliates.
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


package moreexamples;

import database.DatabaseServiceWithPooling;
import oracle.jdbc.OracleType;
import oracle.sql.json.OracleJsonArray;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.time.LocalDateTime;

public class BlogExamples {

    private static OracleJsonFactory factory;

    /**
     * Retrieves the instance of factory and initializes it
     * if the factory is null
     * @return
     */
    private static OracleJsonFactory getJsonFactory() {
        if (BlogExamples.factory == null) {
            BlogExamples.factory = new OracleJsonFactory();
        }
        return BlogExamples.factory;
    }

    /**
     * Demonstrates a simple retrieval of a VARCHAR2 and JSON data type from the profiles table
     * @throws SQLException
     */
    public static void blogExampleA(DatabaseServiceWithPooling pds) throws SQLException {
        final String RETRIEVE_QUERY = "select username, settings from profiles";

        try (Connection connection = pds.getDatabaseConnection()) {
            try (PreparedStatement retrieve_stmt = connection.prepareStatement(RETRIEVE_QUERY)) {
                try (ResultSet rs = retrieve_stmt.executeQuery()) {
                    while (rs.next()) {
                        String username = rs.getObject("username", String.class);
                        String productInformation = rs.getObject("settings", String.class);
                        System.out.println(username + "=" + productInformation);
                    }
                }
            }
        }
    }

    /**
     * Demonstrates retrieving of the JSON column settings and uses filter condition JSON_EXISTS to filter in only
     * the records where the visibility attribute exists and is set to true. In this example, OracleJSONObject is used
     * to process the JSON document and retrieve the values of attributes
     * @param pds
     * @throws SQLException
     */
    public static void blogExampleB(DatabaseServiceWithPooling pds) throws SQLException {
        final String RETRIEVE_QUERY = """
            SELECT p.settings
            FROM profiles p
            WHERE json_exists(p.settings, '$.security?(@.visibility == true)')
            """;
        try (Connection connection = pds.getDatabaseConnection()) {
            try (PreparedStatement retrieve_stmt = connection.prepareStatement(RETRIEVE_QUERY)) {
                try(ResultSet rs = retrieve_stmt.executeQuery()) {
                    while (rs.next()) {
                        OracleJsonObject settings = rs.getObject("settings", OracleJsonObject.class); // 1
                        OracleJsonObject security = settings.get("security").asJsonObject(); // 2
                        System.out.println("version=" +settings.getString("version") + "; security.visibility=" + security.getBoolean("visibility")); // 3
                    }
                }
            }
        }
    }

    /**
     * Demonstrates inserting a new record with JSON data created using OracleJsonFactory and OracleJsonObject
     * @param pds
     * @throws SQLException
     */
    public static void blogExampleC(DatabaseServiceWithPooling pds) throws SQLException {
        final String INSERT_QUERY = "INSERT INTO profiles (username, preferences, settings) VALUES (:1, :2, :3)";

        OracleJsonFactory factory = getJsonFactory(); // 1
        OracleJsonObject preferences = factory.createObject(); // 2
        preferences.put("timezone", "America/Chicago"); // 3
        preferences.put("language", "English (US)");
        preferences.put("theme", "Dark");
        preferences.put("compact", true);

        OracleJsonObject security = factory.createObject();
        security.put("sharing", true);
        security.put("visibility", "private");

        OracleJsonArray keywords = factory.createArray();  // 4
        keywords.add("A");
        keywords.add("B");

        OracleJsonObject settings = factory.createObject();
        settings.put("version", "4.12.1");
        settings.put("level", 1);
        settings.put("security", security); // 5
        settings.put("keywords", keywords); // 6

        try (Connection connection = pds.getDatabaseConnection()) {
            try(PreparedStatement insert_stmt = connection.prepareStatement(INSERT_QUERY)) {
                insert_stmt.setString(1, "normanaberin");
                insert_stmt.setObject(2, preferences, OracleType.JSON); // 7
                insert_stmt.setObject(3, settings, OracleType.JSON);
                int inserted = insert_stmt.executeUpdate();
                System.out.println("inserted:" + inserted);
            }
        }
    }

    /**
     * Demonstrates updating the JSON document settings using JSON_TRANSFORM and adding a new subscription object in an
     * array called subscriptions. Note that with the CREATE ON MISSING handler, if the subscriptions attribute
     * does not exist, then it is created.
     * @param pds
     * @throws SQLException
     */
    public static void blogExampleD(DatabaseServiceWithPooling pds) throws SQLException {
        final String UPDATE_QUERY = """
            UPDATE profiles p 
            SET p.settings = json_transform(p.settings, APPEND '$.subscriptions' = :1 CREATE ON MISSING) 
            WHERE p.profileId = :2
        """;

        final int profileId = 1;
        OracleJsonFactory factory = getJsonFactory();
        OracleJsonObject new_subscription = factory.createObject();
        new_subscription.put("subscriptionId", 10191);
        new_subscription.put("subscriptionName", "Jules");
        new_subscription.put("subscriptionDate", LocalDateTime.now());

        try (Connection connection = pds.getDatabaseConnection()) {
            try(PreparedStatement update_stmt = connection.prepareStatement(UPDATE_QUERY)) {
                update_stmt.setObject(1, new_subscription, OracleType.JSON);
                update_stmt.setInt(2, profileId);
                int updated = update_stmt.executeUpdate();
                System.out.println("updated:" + updated);
            }
        }
    }

    /**
     * Demonstrates updating the full JSON document profiles with a JSON string
     * @param pds
     * @throws SQLException
     */
    public static void blogExampleE(DatabaseServiceWithPooling pds) throws SQLException {
        final String UPDATE_QUERY = "UPDATE profiles SET preferences=:1 WHERE profileId = :2";
        final String jsonstring = "{\"timezone\": \"America/Chicago\"}";
        final int profileId = 1;

        try (Connection connection = pds.getDatabaseConnection()) {
            try(PreparedStatement update_stmt = connection.prepareStatement(UPDATE_QUERY)){
                update_stmt.setString(1, jsonstring);
                update_stmt.setInt(2, profileId );
                int updated = update_stmt.executeUpdate();
                System.out.println("updated:" + updated);
            }
        }
    }
}
