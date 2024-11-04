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
Main - Runner class calling multiple methods
*/

package org.oracle;

import oracle.sql.json.OracleJsonArray;
import oracle.sql.json.OracleJsonFactory;
import oracle.sql.json.OracleJsonObject;

import java.util.ArrayList;

public class Main {
  private static DatabaseConfig pds;
  private static OracleJsonFactory f;

  public static void main(String[] args) {

    pds = new DatabaseConfig();
    f = new OracleJsonFactory();

    // Teams Example
    example1();
    example2();
    example3();
    example4();
    example5();
    example6();

    // BooksExample
    example7();
    example8();
    example9();
  }

  /**
   * Example 1
   * Get all teams
   */
  private static void example1() {
    System.out.println("Example 1: Retrieve all teams using team_info_dv");
    TeamManager.retrieveTeam(pds);
    System.out.println("\n");

  }

  /**
   * Example 2
   * Get specific team
   */
  private static void example2() {
    System.out.println("Example 2: Retrieve specific teams using team_info_dv");
    TeamManager.retrieveTeam(pds, 2);
    System.out.println("\n");
  }

  /**
   * Example 3
   * Create new team using INSERT into team_info_dv
   */
  private static void example3() {

    System.out.println("Example 3: Create a new team using team_info_dv");
    OracleJsonObject withTeamA = f.createObject();
    withTeamA.put("_id", 3);
    withTeamA.put("name", "Mountain Movers");
    withTeamA.put("region", "South America");
    withTeamA.put("color", "cc2222");

    TeamManager.insertNewTeam(pds, withTeamA);
    System.out.println("\n");
  }

  /**
   * Example 4
   * Create new Player in Team using an UPDATE into team_info_dv with
   * JSON_TRANSFORM
   */
  private static void example4() {
    System.out.println("Example 4: Create a new player using JSON_TRANSFORM and team_info_dv");
    OracleJsonObject withPlayerA = f.createObject();
    withPlayerA.put("playerId", 7);
    withPlayerA.put("name", "PLAYER_GABRIEL");
    withPlayerA.put("position", "Support");

    TeamManager.updateTeam(pds, withPlayerA, 3);
    System.out.println("\n");
  }

  /**
   * Example 5
   * Create new Player in Team using INSERT into player_team_info_dv
   */
  private static void example5() {
    System.out.println("Example 5: Create a new player using player_team_info_dv");
    OracleJsonObject withPlayerB = f.createObject();
    withPlayerB.put("_id", 8);
    withPlayerB.put("name", "PLAYER_HARVEY");
    withPlayerB.put("position", "Offense");
    withPlayerB.put("teamId", 3);

    TeamManager.insertNewPlayer(pds, withPlayerB, 3);
    System.out.println("\n");
  }

  /**
   * Example 6
   * Update Team with new players as a whole JSON document using team_info_dv.
   *
   * This example shows that replacing the players with a new
   * set of players remove the old ones from
   * the PLAYERS table.
   *
   * In this example, an OracleJSONObject is created from
   * a copy of the oldTeam and an update on the object is done
   * to replace the players team
   */
  private static void example6() {
    System.out.println("Example 6: ");
    OracleJsonObject withPlayerC = f.createObject();
    withPlayerC.put("playerId", 10);
    withPlayerC.put("name", "PLAYER_MARK");
    withPlayerC.put("position", "Offense");

    OracleJsonObject withPlayerD = f.createObject();
    withPlayerD.put("playerId", 11);
    withPlayerD.put("name", "PLAYER_NATHAN");
    withPlayerD.put("position", "Offense");

    OracleJsonArray newPlayerArr = f.createArray();
    newPlayerArr.add(withPlayerC);
    newPlayerArr.add(withPlayerD);

    int teamId = 1; // Specify which team
    OracleJsonObject oldTeam = TeamManager.retrieveAndReferenceTeam(pds, teamId);
    if (oldTeam != null) {
      OracleJsonObject newTeam = f.createObject(oldTeam);
      newTeam.put("players", newPlayerArr);
      TeamManager.updateTeamAsAWhole(pds, newTeam, teamId);
      System.out.println("\n");
    }
  }

  private static void setLookUp() {
    ArrayList<BookCopyStatus> bookCopyStatusList = new ArrayList<>();
    bookCopyStatusList.add(new BookCopyStatus(1, "Available"));
    bookCopyStatusList.add(new BookCopyStatus(2, "In Circulation"));
    bookCopyStatusList.add(new BookCopyStatus(3, "Reserved"));

    BooksManager.insertNewBookStatusAsList(pds, bookCopyStatusList);
  }

  /**
   * Example 7
   * Insert a record into Book table and 3 records into Book Copies and in a batch
   *
   * Shows the JSON document reflects what is in the relational tables
   */
  private static void example7() {
    BooksManager.insertNewBook(pds, 1, "The New Norm");

    ArrayList<BookCopy> bookCopies = new ArrayList<>();
    bookCopies.add(new BookCopy(1, 1999, 1));
    bookCopies.add(new BookCopy(1, 2000, 1));
    bookCopies.add(new BookCopy(1, 2000, 1));
    BooksManager.insertNewBookCopies(pds, bookCopies);

    BooksManager.retrieveBooks(pds, 1);
  }


  /**
   * Example 8
   * Creates a new JSON object and executes an insert operation into
   * the duality view. Books and Book Copies Table data are retrieved
   * to show the operation reflects on the underlying tables. Finally,
   * the JSON document is retrieved.
   *
   */
  private static void example8() {
    OracleJsonObject copyA = f.createObject();
    copyA.put("year", 2020);
    copyA.put("status", 1);

    OracleJsonObject copyB = f.createObject();
    copyB.put("year", 2021);
    copyB.put("status", 1);

    OracleJsonObject copyC = f.createObject();
    copyC.put("year", 2021);
    copyC.put("status", 3);

    OracleJsonArray bookCopies = f.createArray();
    bookCopies.add(copyA);
    bookCopies.add(copyB);
    bookCopies.add(copyC);

    OracleJsonObject bookA = f.createObject();
    bookA.put("_id", 3);
    bookA.put("name", "Mountain Movers");
    bookA.put("copies", bookCopies);

    BooksManager.insertNewIntoBookDualityView(pds, bookA);
    BooksManager.getBooks(pds);
    BooksManager.getBookCopies(pds);
    BooksManager.retrieveBooks(pds);
  }

  /**
   * Example 9
   * Initially inserts a new book and its copies
   * into the duality view. The inserted book is then
   * retrieved and a new JsonObject is updated.
   * This updated document is used to update the whole
   * document in an UPDATE operation.
   *
   * This example shows that removing copyA from the list
   * of copies, deletes it in the underlying table; while
   * new copies are inserted.
   */
  private static void example9() {
    OracleJsonObject copyA = f.createObject();
    copyA.put("year", 2020);
    copyA.put("status", 1);
    OracleJsonObject copyB = f.createObject();
    copyA.put("year", 2020);
    copyA.put("status", 1);
    OracleJsonObject copyC = f.createObject();
    copyA.put("year", 2023);
    copyA.put("status", 1);

    OracleJsonArray bookCopies = f.createArray();
    bookCopies.add(copyA);

    OracleJsonObject bookA = f.createObject();
    bookA.put("_id", 5);
    bookA.put("name", "Why the Earth spins");
    bookA.put("copies", bookCopies);

    // insert book
    BooksManager.insertNewIntoBookDualityView(pds, bookA);
    BooksManager.retrieveBooks(pds, 5);

    OracleJsonArray newCopies = f.createArray();
    newCopies.add(copyB);
    newCopies.add(copyC);

    // retrieve old document and make the update
    OracleJsonObject book = BooksManager.retrieveAndReferenceBook(pds, 5);
    if (book != null) {
      OracleJsonObject newBook = f.createObject(book);
      newBook.put("copies", newCopies);
      BooksManager.updateBookDualityViewAsAWhole(pds, newBook, 5);
    }

    BooksManager.retrieveBooks(pds, 5);
    BooksManager.getBookCopies(pds);
  }

}