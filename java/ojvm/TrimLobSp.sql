create or replace java source named TrimLob as
/*
 * This SQL script generated a Java code performing BLOB/CLOB operations.
 * The goal is to show Java in the database and contrat its performance with the same code
 * running as a client-side or stand-alone JDBC code.
 */

// You need to import the java.sql package to use JDBC
import java.sql.*;

/* 
 * You need to import the oracle.sql package to use 
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
         DriverManager.getConnection("jdbc:oracle:thin:", "testuser",
          "<your_db_password>");
  }
  long t0,t1;
   /* 
    * auto commit is off by default in OracleJVM (not supported)
    * It's faster with JDBC when auto commit is off
    */
    conn.setAutoCommit (false);
    t0=System.currentTimeMillis(); 
    // Create a Statement
    Statement stmt = conn.createStatement ();

    // clean up 
     try
    {
      stmt.execute ("drop table basic_lob_table");
    }
    catch (SQLException e)
    {
      // An exception could be raised here if the
      // table did not exist already.
    }

    // Create a table containing a BLOB and a CLOB
    stmt.execute ("create table basic_lob_table (x varchar2 (30), " + 
                                 "b blob, c clob)");
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
                          ("select * from basic_lob_table");                   
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
      blob.trim (6);
      clob.trim (6);

      // Show the lob length after trim()
      System.out.println ("Show the lob length after trim()");
      System.out.println ("blob.length()="+blob.length());
      System.out.println ("clob.length()="+clob.length());
    }

    // Close the ResultSet
    rset.close ();

    // Close the Statement 
    stmt.close ();
  
    t1=System.currentTimeMillis(); 
    System.out.println ("====> Duration: "+(int)(t1-t0)+ "Milliseconds");
    // Close the connection
    conn.close ();
  }
}
/

show errors;

alter java source TrimLob compile;

show errors;

create or replace procedure TrimLobSp as 
 language java name 'TrimLob.main(java.lang.String[])';
/

show errors;
set serveroutput on 
call dbms_java.set_output(50000);
 
call TrimLobSp();

