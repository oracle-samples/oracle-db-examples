import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;


/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/*
   DESCRIPTION
    A very basic Java stored procedure sample. For more complex Java stored procedure samples, 
    please explore https://github.com/oracle/oracle-db-examples/tree/master/java/ojvm directory.
    Java stored procedure in the database executed using the KPRB JDBC driver in the Oracle JVM instance.
    To run the sample:
     1. loadjava -user 'jdbcuser/jdbcuser123' -oci8 -resolve -force -verbose JavaStoredProcSample.java
        This loads a java stored procedure in the database.
     2. sqlplus jdbcuser/jdbcuser123 @JavaStoredProcSample.sql
        This calls java stored procedure from sqlplus and print number of emplyoees in the department number 20.
 */

public class JavaStoredProcSample {
  
  final static String DEFAULT_URL = "jdbc:default:connection:";

  // Get the total number of employees for a given department.
  public static int getEmpCountByDept(int deptNo) {
    int count = 0;
    
    try {
     // Get default connection on the current session from the client
     Connection conn = DriverManager.getConnection(DEFAULT_URL);
    
     // Execute a SQL query 
     String sql = "SELECT COUNT(1) FROM EMP WHERE DEPTNO = ?";
     
     // Gets the result value
     try(PreparedStatement pstmt = conn.prepareStatement(sql)) {
       pstmt.setInt(1, deptNo);
       try (ResultSet rs = pstmt.executeQuery()) {
         if (rs.next()) {
           count = rs.getInt(1);
         }
       }
     }
     catch(SQLException sqe) {
       System.out.println(sqe);
     }
    }
    catch(SQLException sqe) {
      System.out.println(sqe);
    }
  
    // Returns the calculated result value
    return count;
  }   
}
