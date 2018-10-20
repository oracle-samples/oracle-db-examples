/*
 * Copyright (c) 2018 Oracle and/or its affiliates. All rights reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
package com.oracle.adbaoverjdbc.test;

import java.sql.Date;
import java.util.function.Consumer;

import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.OperationGroup;
import jdk.incubator.sql2.ParameterizedOperation;
import jdk.incubator.sql2.Session;

/**
 * A utility class to create database objects commonly used by tests, such as
 * a schema of tables and a dummy table.
 */
public class TestFixtures {
  
  private static final String[] CREATE_TEST_SCHEMA_SCRIPT = {
    "CREATE TABLE CITY ("
    + " ID INTEGER,"
    + " NAME VARCHAR(20),"
    + " COUNTRY VARCHAR(20),"
    + " PRIMARY KEY (ID)) ",
    
    "CREATE TABLE FORUM_USER ("
    + " ID INTEGER,"
    + " NAME VARCHAR(20),"
    + " EMAIL VARCHAR(30),"
    + " REFERRED_BY INTEGER,"
    + " CREATED DATE,"
    + " TOTAL_SCORE INTEGER,"
    + " BEST_POST_SCORE INTEGER,"
    + " CITY_ID INTEGER,"
    + " PRIMARY KEY (ID),"
    + " FOREIGN KEY (CITY_ID) REFERENCES CITY(ID))",
    
    "CREATE TABLE POST ("
    + " TITLE VARCHAR(40),"
    + " USER_NAME VARCHAR(30),"
    + " VIEWS INTEGER,"
    + " COMMENTS INTEGER)",
    
    "CREATE TABLE TIER ("
    + " TIER_NUM INTEGER,"
    + " MIN_SCORE INTEGER,"
    + " MAX_SCORE INTEGER)"
  };
  
  private static final String[] DROP_TEST_SCHEMA_SCRIPT = {
    "DROP TABLE FORUM_USER",
    "DROP TABLE CITY",
    "DROP TABLE POST",
    "DROP TABLE TIER"
  };
  
  private static final String[] CREATE_DUMMY_SCRIPT = {
    "CREATE TABLE dummy (dumbval VARCHAR(1))",
    "INSERT INTO dummy VALUES ('X')"
  };
  
  private static final String[] DROP_DUMMY_SCRIPT = {
    "DROP TABLE dummy"
  };
  
  private static final City[] CITIES = {
    new City(10, "TOKYO", "JAPAN"),
    new City(20, "SAN FRANCISCO", "UNITED STATES"),
    new City(30, "PARIS", "FRANCE"),
    new City(40, "LONDON", "UNITED KINGDOM"),
  };
  
  private static final User[] USERS = {
    new User(7369, "DOUGLAS", "douglas@example.com", 7902, Date.valueOf("1980-12-17"), 
                 800, null, 20), 
    new User(7499, "JEAN", "jean@example.com", 7698, Date.valueOf("1981-2-20"), 
                 1600, 300, 30), 
    new User(7521, "LANCE", "lance@example.com", 7698, Date.valueOf("1981-2-22"), 
                 1250, 500, 30), 
    new User(7566, "CODD", "codd@example.com", 7839, Date.valueOf("1981-4-2"), 
                 2975, null, 20), 
    new User(7654, "STALEY", "staley@example.com", 7698, Date.valueOf("1981-9-28"), 
                 1250, 1400, 30), 
    new User(7698, "CLEMENTS", "clements@example.com", 7839, Date.valueOf("1981-5-1"), 
                 2850, null, 30), 
    new User(7782, "OGORMAN", "orgorman@example.com", 7839, Date.valueOf("1981-6-9"), 
                 2450, null, 10), 
    new User(7788, "KURFESS", "kurfess@example.com", 7566, Date.valueOf("1987-7-13"), 
                 3000, null, 20), 
    new User(7839, "FISHER", "fisher@example.com", null, Date.valueOf("1981-11-17"), 
                 5000, null, 10), 
    new User(7844, "LIU", "liu@example.com", 7698, Date.valueOf("1981-9-8"), 
                 1500, 0, 30), 
    new User(7876, "NAKA", "naka@example.com", 7788, Date.valueOf("1987-7-13"), 
                 1100, null, 20), 
    new User(7900, "MIYAMOTO", "miyamoto@example.com", 7698, Date.valueOf("1981-12-3"), 
                 950, null, 30), 
    new User(7902, "KOJIMA", "kojima@example.com", 7566, Date.valueOf("1981-12-3"), 
                 3000, null, 20), 
    new User(7934, "IWATA", "iwata@example.com", 7782, Date.valueOf("1982-1-23"), 
                 1300, null, 10)                    
  };
  
  private static final Tier[] TIERS = {
    new Tier(1, 700, 1200),
    new Tier(2, 1201, 1400),
    new Tier(3, 1401, 2000),
    new Tier(4, 2001, 3000),
    new Tier(5, 3001, 9999)
  };
  
  /**
   * Creates the following tables and populates them with data:
   * <pre>
   * CREATE TABLE CITY(
   *   ID INTEGER,
   *   NAME VARCHAR(14),
   *   COUNTRY VARCHAR(13),
   *   PRIMARY KEY (ID))
   * 
   * CREATE TABLE FORUM_USER(
   *   ID INTEGER,
   *   NAME VARCHAR(10),
   *   EMAIL VARCHAR(30),
   *   REFERRED_BY INTEGER,
   *   CREATED DATE,
   *   TOTAL_SCORE INTEGER,
   *   BEST_POST_SCORE INTEGER,
   *   CITY_ID INTEGER,
   *   PRIMARY KEY (ID),
   *   FOREIGN KEY (CITY_ID) REFERENCES CITY(ID))
   * 
   * CREATE TABLE POST(
   *   TITLE VARCHAR(10),
   *   USER_NAME VARCHAR(30),
   *   VIEWS INTEGER,
   *   COMMENTS INTEGER)
   * 
   * CREATE TABLE TIER(
   *   TIER_NUM INTEGER,
   *   MIN_SCORE INTEGER,
   *   MAX_SCORE INTEGER)
   * </pre>
   * <br>
   * For exact data values, see the private USERS, CITIES, and TIERS fields 
   * defined in this class. The POST table has no populated values.
   * <br>
   * This method returns after all changes are committed.
   * @param session Session to create tables on.
   */
  public static void createTestSchema(Session session) {
    dropTestSchema(session);
    OperationGroup<?,?> createGroup = session;
    submitSQL(createGroup, CREATE_TEST_SCHEMA_SCRIPT);
    submitDML(createGroup, 
               "INSERT INTO CITY VALUES (?, ?, ?)", CITIES);
    submitDML(createGroup, 
               "INSERT INTO FORUM_USER VALUES (?, ?, ?, ?, ?, ?, ?, ?)", USERS);
    submitDML(createGroup,
               "INSERT INTO TIER VALUES (?, ?, ?)", TIERS);
    commit(session);
  }

  /**
   * Drops tables created by a previous call to 
   * {@link #createTestSchema(Session)}. 
   * <br>
   * This method returns after the changes are committed.
   * @param session Session to drop tables on.
   */
  public static void dropTestSchema(Session session) {
    //TODO: When independent works:
//    submitSQL(session.operationGroup().independent(),
    // For now, submitSQL injects catchOperations 
    submitSQL(session, DROP_TEST_SCHEMA_SCRIPT);
    commit(session);
  }
  
  /**
   * Creates a dummy table named "dummy". The table has one column and one row,
   * which allows SQL like "SELECT 'abc', 'xyz' FROM dummy" to return one row 
   * of the two column values: 'abc' and 'xyz'.
   * <br>
   * This method returns after the changes are committed.
   * @param session Session to create tables on.
   */
  public static void createDummyTable(Session session) {
    dropDummyTable(session);
    submitSQL(session, CREATE_DUMMY_SCRIPT);
    commit(session);
  }

  /**
   * Drops tables created by a previous call to createDummyTable.
   * This method returns after the changes are committed.
   * @param session Session to drop tables on.
   */
  public static void dropDummyTable(Session session) {
    submitSQL(session, DROP_DUMMY_SCRIPT);
    commit(session);
  }
  
  private static void submitSQL(OperationGroup<?,?> opGroup, String... sqls) {
    for (String sql : sqls) {
      opGroup.operation(sql)
        .timeout(TestConfig.getTimeout())
        .onError(err -> System.err.println(sql + " : " + err.getMessage()))
        .submit();
      opGroup.catchErrors();
    }
  }
  
  private static void submitDML(OperationGroup<?,?> opGroup, String sql,
                                ParameterObject... pObjs) {
    Consumer<Throwable> sqlPrintFn = 
      err -> System.err.println(sql + " : " + err.getMessage());
    
    for (ParameterObject pObj : pObjs) {
      ParameterizedOperation<?> pOp = opGroup.rowCountOperation(sql);
      pObj.setParameters(pOp);
      pOp.timeout(TestConfig.getTimeout())
        .onError(sqlPrintFn)
        .submit();
    }
  }
  
  private static void commit(Session session) {
    try {
      session.endTransactionOperation(session.transactionCompletion())
        .timeout(TestConfig.getTimeout())
        .submit()
        .getCompletionStage()
        .toCompletableFuture()
        .get();
    }
    catch (Exception e) {
      throw new RuntimeException(e);
    }
  }
  
  private interface ParameterObject {
    void setParameters(ParameterizedOperation<?> pOp);
  }
  
  private static class User implements ParameterObject {
    final int id;
    final String name;
    final String email;
    final Integer referredBy;
    final Date created;
    final Integer totalScore;
    final Integer bestPostScore;
    final int cityId;
    
    User(int empno, String name, String email, Integer referredBy, Date created,
             Integer totalScore, Integer bestPostScore, int cityId) {
      this.id = empno;
      this.name = name;
      this.email = email;
      this.referredBy = referredBy;
      this.created = created;
      this.totalScore = totalScore;
      this.bestPostScore = bestPostScore;
      this.cityId = cityId;
    }

    @Override
    public void setParameters(ParameterizedOperation<?> pOp) {
      pOp.set("1", id, AdbaType.INTEGER)
        .set("2", name, AdbaType.VARCHAR)
        .set("3", email, AdbaType.VARCHAR)
        .set("4", referredBy, AdbaType.INTEGER)
        .set("5", created, AdbaType.DATE)
        .set("6", totalScore, AdbaType.INTEGER)
        .set("7", bestPostScore, AdbaType.INTEGER)
        .set("8", cityId, AdbaType.INTEGER);
    }
  }
  
  private static class City implements ParameterObject {
    private final int id;
    private final String name;
    private final String country;
    
    City(int deptno, String dname, String loc) {
      this.id = deptno;
      this.name = dname;
      this.country = loc;
    }
    
    @Override
    public void setParameters(ParameterizedOperation<?> pOp) {
      pOp.set("1", id, AdbaType.INTEGER)
        .set("2", name, AdbaType.VARCHAR)
        .set("3", country, AdbaType.VARCHAR);
    } 
  }
  
  private static final class Tier implements ParameterObject {
    private final Integer level;
    private final Integer minScore;
    private final Integer maxScore;
    
    Tier(Integer grade, Integer losal, Integer hisal) {
      this.level = grade;
      this.minScore = losal;
      this.maxScore = hisal;
    }

    @Override
    public void setParameters(ParameterizedOperation<?> pOp) {
      pOp.set("1", level, AdbaType.INTEGER)
        .set("2", minScore, AdbaType.INTEGER)
        .set("3", maxScore, AdbaType.INTEGER);
    }
  }
}
