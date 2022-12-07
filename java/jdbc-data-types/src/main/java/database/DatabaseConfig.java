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
