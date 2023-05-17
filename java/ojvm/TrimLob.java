/*
/------------------------------------------------------------------------------
/ Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
/
/ Portions Copyright 2006-2015, Kuassi Mensah. All rights reserved.
/
/
/------------------------------------------------------------------------------
/ DESCRIPTION
/ This sample shows basic BLOB/CLOB operations. It drops, creates, and populates a basic_lob_table
/ with blob, clob data types columns then fetches the rows and trim both LOB and CLOB
*/

// Need to import the java.sql package to use JDBC
import java.sql.*;

/* 
 * Need to import the oracle.sql package to use 
 * oracle.sql.BLOB
 */
import oracle.sql.*;

public class TrimLob
{
  public static void main (String args []) throws SQLException {
  Connection conn;
 /*
  * Where is your code running: in the database or outside?
  */
  if (System.getProperty("oracle.jserver.version") != null)
  {
  /* 
   * You are in the database, already connected, use the default 
   * connection
   */
  conn = DriverManager.getConnection("jdbc:default:connection:");
  }
  else
  {
  /* 
   * You are not in the database, you need to connect to 
   * the database
   */

   DriverManager.registerDriver(new oracle.jdbc.OracleDriver());  
   conn = 
         DriverManager.getConnection("jdbc:oracle:thin:@localhost:1522/orcl", "testuser",
          "<your_db_password>");
  }
  long t0,t1;
   /* 
    * auto commit is off (not suported)by default in OracleJVM
    * It's faster with JDBC when auto commit is off
    */
    conn.setAutoCommit (false);
    t0=System.currentTimeMillis(); 
    // Create a Statement
    Statement stmt = conn.createStatement ();
    // Make sure the table is empty
    stmt.execute("delete from basic_lob_table");
    stmt.execute("commit"); 

    // Populate the table
    stmt.execute ("insert into basic_lob_table values ('first', " +
                  "'010101010101010101010101010101', " +
                  "'one.two.three.four.five.six.seven')");
    stmt.execute ("insert into basic_lob_table values ('second', " +
                  "'0202020202020202020202020202020202020202', " +
                  "'two.three.four.five.six.seven.eight.nine.ten')");
    
   /* 
    * Retive Lobs and modify contents; this can be done by doing
    * "select ... for update", but "autocommit" is turned off and
    * the previous "create table" statement already locks the table 
    */
    ResultSet rset = stmt.executeQuery
                          ("select * from basic_lob_table for update");                   
    while (rset.next ())
    {
      // Get the lobs
      BLOB blob = (BLOB) rset.getObject (2);
      CLOB clob = (CLOB) rset.getObject (3);

      // Show the original lob length
      System.out.println ("Show the original lob length");
      System.out.println ("blob.length()="+blob.length());
      System.out.println ("clob.length()="+clob.length());

      // Trim the lobs
      System.out.println ("Trim the lob to legnth = 6");
      blob.truncate (6);
      clob.truncate (6);

      // Show the lob length after trim()
      System.out.println ("Show the lob length after trim()");
      System.out.println ("blob.length()="+blob.length());
      System.out.println ("clob.length()="+clob.length());
    }

    // Close the ResultSet and Commit changes
    rset.close ();
    stmt.execute("commit"); 

    // Close the Statement 
    stmt.close ();
  
    t1=System.currentTimeMillis(); 
    System.out.println ("====> Duration: "+(int)(t1-t0)+ "Milliseconds");
    // Close the connection
    conn.close ();
  }
}
