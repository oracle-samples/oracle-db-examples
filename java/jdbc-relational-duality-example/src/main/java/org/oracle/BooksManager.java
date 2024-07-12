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
BooksManager - Class that has requests methods for Books and Book Copy tables and their duality view
*/

package org.oracle;

import oracle.jdbc.OracleType;
import oracle.sql.json.OracleJsonObject;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.List;

public class BooksManager {
  
  public static void retrieveBooks(DatabaseConfig pds) {
    retrieveAllBooksDualityView(pds, -1);
  }
  
  public static void retrieveBooks(DatabaseConfig pds, int withBookId) {
    retrieveAllBooksDualityView(pds, withBookId);
  }
  
  public static void insertNewIntoBookDualityView(DatabaseConfig pds, OracleJsonObject data) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(
    "insert into book_copy_dv values (?)")) {
      stmt.setObject(1, data, OracleType.JSON);
      
      int created = stmt.executeUpdate();
      if (created > 0)
      System.out.println("New Book and book copies created");
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  private static void retrieveAllBooksDualityView(DatabaseConfig pds, int withBookId) {
    String query = withBookId > 0 ? "SELECT data FROM book_copy_dv WHERE json_value(data, '$._id') = ?" : "SELECT data FROM book_copy_dv";
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(query)) {
      
      if (withBookId > 0) {
        stmt.setInt(1, withBookId);
      }
      
      try (ResultSet rs = stmt.executeQuery()) {
        while (rs.next()) {
          OracleJsonObject book = rs.getObject(1, OracleJsonObject.class);
          System.out.println(book.toString());
        }
      }
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static OracleJsonObject retrieveAndReferenceBook(DatabaseConfig pds, int withBookId) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement("SELECT data FROM book_copy_dv WHERE json_value(data, '$._id') = ?")) {
      
      stmt.setInt(1, withBookId);
      try (ResultSet rs = stmt.executeQuery()) {
        if (rs.next()) {
          return rs.getObject(1, OracleJsonObject.class);
        }
      }
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
    return null;
  }
  
  public static void updateBookDualityViewAsAWhole(DatabaseConfig pds, OracleJsonObject data, int withBookId) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection
    .prepareStatement("UPDATE book_copy_dv dv SET dv.data = ? where JSON_VALUE(dv.data, '$._id') = ?")) {
      stmt.setObject(1, data, OracleType.JSON);
      stmt.setInt(2, withBookId);
      
      int i = stmt.executeUpdate();
      if (i > 0)
      System.out.println("Updated book information");
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void insertNewBook(DatabaseConfig pds, String name) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(
    "insert into BOOKS(BOOK_NAME) values (?)")) {
      stmt.setString(1, name);
      
      int created = stmt.executeUpdate();
      if (created > 0)
      System.out.println("New book added.");
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void insertNewBook(DatabaseConfig pds, int id, String name) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(
    "insert into BOOKS(BOOK_ID, BOOK_NAME) values (?, ?)")) {
      stmt.setInt(1, id);
      stmt.setString(2, name);
      
      int created = stmt.executeUpdate();
      if (created > 0)
      System.out.println("New book added.");
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void insertNewBookStatus(DatabaseConfig pds, int id, String name) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(
    "insert into COPY_STATUS_LU(STATUS_ID, STATUS_NAME) values (?, ?)")) {
      stmt.setInt(1, id);
      stmt.setString(2, name);
      
      int created = stmt.executeUpdate();
      if (created > 0)
      System.out.println("New status added.");
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void insertNewBookStatusAsList(DatabaseConfig pds, List<BookCopyStatus> statusList) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(
    "insert into COPY_STATUS_LU(STATUS_ID, STATUS_NAME) values (?, ?)")) {
      
      for (BookCopyStatus status : statusList) {
        stmt.setInt(1, status.getStatusId());
        stmt.setString(2, status.getStatusName());
        stmt.addBatch();
        
        stmt.clearParameters();
        
      }
      
      int[] created = stmt.executeBatch();
      for (int i = 0; i < created.length; i++) {
        if (created[i] > 0)
        System.out.println("New status added.");
        else System.out.println("Failed to add new status.");
        
      }
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void insertNewBookCopy(DatabaseConfig pds, int bookId, int yearPublished, int statusId) {
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(
    "insert into BOOK_COPY(BOOK_ID, YEAR_PUBLISHED, STATUS_ID) values (?, ?, ?)")) {
      stmt.setInt(1, bookId);
      stmt.setInt(2, yearPublished);
      stmt.setInt(3, statusId);
      
      int created = stmt.executeUpdate();
      if (created > 0)
      System.out.println("New book copy added.");
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void insertNewBookCopies(DatabaseConfig pds, List<BookCopy> copies) {
    
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(
    "insert into BOOK_COPY(BOOK_ID, YEAR_PUBLISHED, STATUS_ID) values (?, ?, ?)")) {
      
      for (BookCopy bookCopy : copies) {
        stmt.setInt(1, bookCopy.getBookId());
        stmt.setInt(2, bookCopy.getYearPublished());
        stmt.setInt(3, bookCopy.getStatusId());
        stmt.addBatch();
        
        stmt.clearParameters();
      }
      
      
      int[] created = stmt.executeBatch();
      for (int i = 0; i < created.length; i++) {
        if (created[i] > 0)
        System.out.println("New book copy added.");
        else System.out.println("Failed to add a new book copy.");
      }
      
      
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void getBooks(DatabaseConfig pds) {
    String query = "SELECT * FROM books";
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(query)) {
      try (ResultSet rs = stmt.executeQuery()) {
        while (rs.next()) {
          int bookId = rs.getInt(1);
          String bookName = rs.getString(2);
          System.out.println(bookId + " - " + bookName);
        }
      }
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
  
  public static void getBookCopies(DatabaseConfig pds) {
    String query = """
                SELECT bc.BOOK_COPY_ID, bc.BOOK_ID, b.BOOK_NAME,  bc.YEAR_PUBLISHED, cs.STATUS_NAME 
                FROM book_copy bc, copy_status_lu cs, books b 
                WHERE bc.STATUS=cs.STATUS_ID and bc.BOOK_ID=b.BOOK_ID
                """;
    
    try (
    Connection connection = pds.getDatabaseConnection();
    PreparedStatement stmt = connection.prepareStatement(query)) {
      
      try (ResultSet rs = stmt.executeQuery()) {
        while (rs.next()) {
          
          int bookCopyId = rs.getInt(1);
          int bookId = rs.getInt(2);
          String bookName = rs.getString(3);
          int publishedYear = rs.getInt(4);
          String status = rs.getString(5);
          System.out.println("ID:" + bookId + " " + bookCopyId + " - " + bookName + ", " + publishedYear + " [" +status+ "]x");
        }
      }
      
    } catch (SQLException e) {
      e.printStackTrace();
    }
  }
}

class BookCopyStatus {
  final int statusId;
  final String statusName;
  
  BookCopyStatus(int statusId, String statusName) {
    this.statusId = statusId;
    this.statusName = statusName;
  }
  
  public int getStatusId() {
    return statusId;
  }
  
  public String getStatusName() {
    return statusName;
  }
}

class BookCopy {
  final int bookId;
  final int yearPublished;
  final int statusId;
  
  BookCopy(int bookId, int yearPublished, int statusId) {
    this.bookId = bookId;
    this.yearPublished = yearPublished;
    this.statusId = statusId;
  }
  
  public int getBookId() {
    return bookId;
  }
  
  public int getStatusId() {
    return statusId;
  }
  
  public int getYearPublished() {
    return yearPublished;
  }
}


