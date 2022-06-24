/* Copyright (c) 2018, Oracle and/or its affiliates. All rights reserved.*/

/**
 * DESCRIPTION
 *
 * A simplified sample of Create, Read, Update and Delete (CRUD) operations using
 * PreparedStatements to demonstrate connection to Oracle Database XE and get 
 * users running queries against their database as quickly as possible. The following
 * code was written with brevity, simplicity and minimalism in mind and is not meant
 * for production purposes.
 * 
 * DEPENDENCIES/REQUIREMENTS
 * 
 * A. This sample expects the simplified table, ISSUES, to exist. The setup script
 * is available in the following file:
 * 
 *      PreparedStatementSimplifiedSample.sql
 * 
 * COMMENTS 
 * 
 * 1 - This is a basic CommandLineRunner Spring-boot application 
 * 2 - jdbc:oracle:thin@//[hostname]:[port]/[DB service name] For XE local installations, the value below is the default
 * 3 - Inserts a new record in the ISSUES table (Can be commented out for testing)
 * 4 - Updates an existing record's STATUS to an arbitrary number with a given ID (Can be commented out for testing)
 * 5 - Delete an existing record with a given ID (Can be commented out for testing)
 * 6 - Prints out every record and its columns in the ISSUES table
 * 
 */

import oracle.jdbc.pool.OracleDataSource;
import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;


@SpringBootApplication // 1
public class PreparedStatementSimplifiedSample implements CommandLineRunner {
    
    public static void main(String[] args) {
        SpringApplication.run(XeApplication.class, args);
    }

    @Override
    public void run(String... args) throws Exception {

        // 1
        OracleDataSource ods = new OracleDataSource();
        ods.setURL("jdbc:oracle:thin:@//localhost:1521/XEPDB1"); // 2
        ods.setUser("[username]");
        ods.setPassword("[password]]");
        Connection conn = ods.getConnection();

		// 3 
       	PreparedStatement insert = conn.prepareStatement("insert into ISSUES(ISSUE_TITLE, ISSUE_BY) values (?, ?)");
       	insert.setString(1, "Requesting project access for New Hire");
       	insert.setString(2, "Mark");
       	insert.execute();

		// 4
       	PreparedStatement update = conn.prepareStatement("update ISSUES set ISSUE_STATUS=? where ISSUE_ID=?");
       	update.setInt(1, 7);
       	update.setInt(2, 1);
       	update.execute();

		// 5
        PreparedStatement delete = conn.prepareStatement("delete ISSUES where ISSUE_ID=?");
        delete.setInt(1, 1);
        delete.execute();

		// 6
        PreparedStatement select = conn.prepareStatement("select * from ISSUES");
        ResultSet rslt = select.executeQuery();
        while (rslt.next()) {
            System.out.println("-----");
            System.out.println(" ID: " + rslt.getInt("ISSUE_ID"));
            System.out.println(" BY: " + rslt.getString("ISSUE_BY"));
            System.out.println(" ON: " + rslt.getDate("ISSUE_ON").toString());
            System.out.println(" ABT: " + rslt.getString("ISSUE_TITLE"));
            System.out.println(" STA: " + rslt.getInt("ISSUE_STATUS"));
        }

    }
}
