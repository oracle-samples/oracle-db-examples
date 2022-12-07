/* Copyright (c) 2022, Oracle and/or its affiliates. All rights reserved.

DESCRIPTION
DatabaseConfig - Used to retrieve database productInformation from a source (e.g. environment variables).
Set Environment variables or configure this file with your connection details.
*/
package database;

public class DatabaseConfig {

    private static final String DB_USER = System.getenv("db.user");
    private static final String DB_URL = System.getenv("db.url");
    private static final String DB_PASSWORD = System.getenv("db.password");

    public static String getDbUser() {
        return DB_USER;
    }

    public static String getDbUrl() {
        return DB_URL;
    }

    public static String getDbPassword() {
        return DB_PASSWORD;
    }

}
