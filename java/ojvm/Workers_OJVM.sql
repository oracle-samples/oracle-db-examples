REM
REM
REM ------------------------------------------------------------------------------
REM  Copyright (c) 2017, Oracle and/or its affiliates. All rights reserved.
REM
REM Portions Copyright 2006-2015, Kuassi Mensah. All rights reserved.
REM https://www.amazon.com/dp/1555583296
REM Adapated from existing JDBC demo.
REM
REM ------------------------------------------------------------------------------
REM DESCRIPTION
REM The following code sample runs directly in the database (using OJVM).
REM  It retrieves a worker from a database, then updates its position and salary.
REM
create or replace and resolve java source named Workers as
 
import java.sql.*;
import oracle.jdbc.driver.*;

public class Workers 
{
  
  public static void main (String args []) throws SQLException {
  
     String name = null;
     String pos = null;
     int sal;
     int id;
     long t0,t1;
     Connection conn = null;
     Statement stmt = null;
     PreparedStatement pstmt = null;
     
     if ( args.length < 1 ) {
      System.err.println("Usage: Java Workers <wid> <new position> <new salary>");
      System.exit(1);
      }
      
     // Get parameters value
     id = Integer.parseInt(args[0]);
     pos = args[1];
     sal = Integer.parseInt(args[2]);     
    
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
  	System.out.println ("Running in OracleJVM,  in the database!");
  	}
  	else
  	{
  	/* 
   	* You are not in the database, you need to connect to 
   	* the database
   	*/

   	DriverManager.registerDriver(new oracle.jdbc.OracleDriver());  
   	conn = DriverManager.getConnection("jdbc:oracle:thin:", 
         				         "testuser", "<your_db_password>");
        System.out.println ("Running in JDK VM, outside the database!");
        }
     
     /* 
      * Auto commit is off by default in OJVM
      * Set auto commit off in client JDBC
      */
      conn.setAutoCommit (false);
     
      // Start timing
         t0=System.currentTimeMillis(); 
     
     /*
      * find the name of the workers given his id number
      */
        
      // create statement
         stmt = conn.createStatement();
      
      // find the name of the worker 
         ResultSet rset = stmt.executeQuery(
               "SELECT WNAME FROM workers WHERE wid = " + id);

      // retrieve and print the result (we are only expecting 1 row
         while (rset.next()) 
         {
          name = rset.getString(1);
         }
    
      // return the name of the worker who has the given worker number
         System.out.println ("Worker Name: "+ name);
       
      /*
       * update the position and salary of the retrieved worker
       */

     // prepare the update statement
          pstmt = conn.prepareStatement("UPDATE WORKERS SET WPOSITION = ?, " +
              " WSALARY = ? WHERE WNAME = ?");

     // set up bind values and execute the update
          pstmt.setString(1, pos);
          pstmt.setInt(2, sal);
          pstmt.setString(3, name);
          pstmt.execute();

     // double-check (retrieve) the updated position and salary
         rset = stmt.executeQuery(
         "SELECT WPOSITION, WSALARY FROM WORKERS WHERE WNAME = '" + 
                              name + "'");
         while (rset.next()) 
         {
          pos = rset.getString ("wposition");
          sal = rset.getInt ("wsalary");
         } 
       System.out.println ("Worker: Id = " + id + ", Name = " + name + 
                   ", Position = " + pos + ", Salary = " + sal);
  	   
     // Close the ResultSet
        rset.close();
        
     // Close the Statement
        stmt.close();
  
     // Stop timing
        t1=System.currentTimeMillis(); 
        System.out.println ("====> Duration: "+(int)(t1-t0)+ " Milliseconds");

     // Close the connection
        conn.close();     
   }
 }

/
show errors;

create or replace procedure WorkerSP (wid IN varchar2,wpos IN
varchar2, wsal IN varchar2) as
language java name 'Workers.main(java.lang.String[])';
/
show errors;

set serveroutput on
call dbms_java.set_output(50000);
call WorkerSp('621', 'Senior VP', '650000');
