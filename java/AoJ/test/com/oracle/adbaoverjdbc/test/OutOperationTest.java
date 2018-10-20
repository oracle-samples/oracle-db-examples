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
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.Submission;
import static com.oracle.adbaoverjdbc.test.TestConfig.*;

/**
 * This is a quick and dirty test to check if anything at all is working.
 */
public class OutOperationTest {

    // Define these three constants with the appropriate values for the database
    // and JDBC driver you want to use. Should work with ANY reasonably standard
    // JDBC driver. These values are passed to DriverManager.getSession.
    public static final String URL = getUrl();
    public static final String USER = getUser();
    public static final String PASSWORD = getPassword();

    public static final String FACTORY_NAME = getDataSourceFactoryName();
    private static final String PROC_NAME = "emp_by_num";

    /**
     * Do something that approximates real work. Do a transaction. Uses
     * TransactionCompletion, CompletionStage args, and catch Operation.
     */
//    @Test
    // TODO: PLSQL only works on oracle
    public void outOperationTest() {
        DataSourceFactory factory = DataSourceFactory.newFactory(FACTORY_NAME);

        try (DataSource ds = factory.builder()
                .url(URL)
                .username(USER)
                .password(PASSWORD)
                .build();
                Session session = ds.getSession(t -> System.out.println("ERROR: " + t.toString()))) {

            createProc(session);

            final int empno = 7369;
            invokeProc(session, empno);
            dropProc(session);
        }
        ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
    }

    private void createProc(Session session) {
        String sql = 
                "CREATE OR REPLACE PROCEDURE "+PROC_NAME+"(given_num IN NUMBER, "
                                                        + "out_name OUT VARCHAR2, "
                                                        + "out_job OUT VARCHAR2, "
                                                        + "out_mgr OUT NUMBER, "
                                                        + "out_hiredate OUT DATE, "
                                                        + "out_sal OUT NUMBER, "
                                                        + "out_comm OUT NUMBER, "
                                                        + "out_deptno OUT NUMBER) IS "
                + "BEGIN "
                    + "SELECT ename, job, mgr, hiredate, sal, comm, deptno "
                        + "INTO out_name, out_job, out_mgr, out_hiredate, out_sal, out_comm, out_deptno "
                        + "FROM EMP WHERE id=given_num; "
                + "END; ";
        
        session.operation(sql).submit();
    }

    private void invokeProc(Session session, int empNo) {
        String sql = "CALL "+PROC_NAME+"(?, ?, ?, ?, ?, ?, ?, ?) ";

        Submission<Employee> submission = session.<Employee>outOperation(sql)
                .set("1", empNo, AdbaType.INTEGER)
                .outParameter("2", AdbaType.VARCHAR)
                .outParameter("3", AdbaType.VARCHAR)
                .outParameter("4", AdbaType.INTEGER)
                .outParameter("5", AdbaType.DATE)
                .outParameter("6", AdbaType.INTEGER)
                .outParameter("7", AdbaType.INTEGER)
                .outParameter("8", AdbaType.INTEGER)
                .apply(out -> {
                    return new Employee(empNo,
                            out.at(2).get(String.class),
                            out.at(3).get(String.class),
                            out.at(4).get(Integer.class),
                            out.at(5).get(Date.class),
                            out.at(6).get(Integer.class),
                            out.at(7).get(Integer.class),
                            out.at(8).get(Integer.class));
                })
                .submit();

        CompletableFuture<Employee> cf = submission.getCompletionStage().toCompletableFuture();
        cf.thenAccept(emp -> {
            System.out.println("Emp Record : " + emp);
        });
    }
    
    private void dropProc(Session session) {
        String sql = "DROP PROCEDURE "+PROC_NAME;
        session.operation(sql).submit();
    }
    
    static public class Employee {
        private final int empNo;
        private final String eName;
        private final String job;
        private final int mgr;
        private final Date hireDate;
        private final int sal;
        private final int comm;
        private final int deptNo;
        
        public Employee(Integer empNo, String eName, String job, Integer mgr, Date hireDate, Integer sal, Integer comm, Integer deptNo) {
            this.empNo = empNo==null?0:empNo;
            this.eName = eName;
            this.job = job;
            this.mgr = mgr==null?0:mgr;
            this.hireDate = hireDate;
            this.sal = sal==null?0:sal;
            this.comm = comm==null?0:comm;
            this.deptNo = deptNo==null?0:deptNo;
        }
        
        @Override
        public String toString() {
            return "\nEMPNO: " + empNo 
                    + "\nENAME: " + eName 
                    + "\nJOB: " + job 
                    + "\nMGR: " + mgr 
                    + "\nHIREDATE: " + hireDate 
                    + "\nSAL: " + sal 
                    + "\nCOMM: " + comm 
                    + "\nDEPTNO: " + deptNo;
        }
    }

}
