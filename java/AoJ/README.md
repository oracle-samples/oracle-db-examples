# AoJ: ADBA over JDBC

ADBA is Asynchronous Database Access, a non-blocking database access api that Oracle is proposing as a Java standard. ADBA was announced at [JavaOne 2016](https://static.rainfocus.com/oracle/oow16/sess/1461693351182001EmRq/ppt/CONF1578%2020160916.pdf) and presented again at [JavaOne 2017](http://www.oracle.com/technetwork/database/application-development/jdbc/con1491-3961036.pdf). The ADBA source is available for download from the [OpenJDK sandbox](http://hg.openjdk.java.net/jdk/sandbox/file/729f80d0cf31/src/jdk.incubator.adba/share/classes) as part of the OpenJDK project. You can get involved in the ADBA specification effort by following the [JDBC Expert Group mailing list](http://mail.openjdk.java.net/pipermail/jdbc-spec-discuss/). 

Reading a bunch of JavaDoc and interfaces can be interesting, but it is not nearly as engaging as having actual running code to play with. To that end, we have uploaded the beginnings of an implementation of ADBA running over standard JDBC, AoJ. AoJ is available for download from [GitHub](https://github.com/oracle/oracle-db-examples/upload/master/java/AoJ) under the Apache license. It should run with any reasonably standard compliant JDBC driver.

AoJ implements only a small part of ADBA, but it is enough to write interesting code. It provides partial implementations of DataSourceFactory, DataSource, Connection, OperationGroup, RowOperation, CountOperation, Transaction and others. These implementations are not complete but there is enough there to write interesting database programs. The code that is there is untested, but it does work to some extent. The saving grace is that you can download the source and improve it: add new features, fix bugs, try out alternate implementations.

Oracle is not proposing AoJ as an open source project. However, because AoJ is released under the Apache license, the Java community can fork the code and create a true open source project with this upload as a base. Oracle developers may contribute when we have time, but this would have to be a Java community effort.

We could have held this code back and worked on it longer. Instead we thought it better to get it to the community as soon as we could. We hope that you agree.

## Sample Code

The following test case should give you some idea of what AoJ can do. It uses the scott/tiger [schema](https://github.com/oracle/dotnet-db-samples/blob/master/schemas/scott.sql). It should run with any JDBC driver connecting to a database with the scott schema.

`````` public void transactionSample() {
   DataSourceFactory factory = DataSourceFactory.forName("com.oracle.adbaoverjdbc.DataSourceFactory");
   try (DataSource ds = factory.builder()
           .url(URL)
           .username(“scott")
           .password(“tiger")
           .build();
           Connection conn = ds.getConnection(t -> System.out.println("ERROR: " + t.getMessage()))) {
     Transaction trans = conn.transaction();
     CompletionStage<Integer> idF = conn.<Integer>rowOperation("select empno, ename from emp where ename = ? for update")
             .set("1", "CLARK", AdbaType.VARCHAR)
             .collect(Collector.of(
                     () -> new int[1], 
                     (a, r) -> {a[0] = r.get("empno", Integer.class); },
                     (l, r) -> null,
                     a -> a[0])
             )
             .submit()
             .getCompletionStage();
     conn.<Long>countOperation("update emp set deptno = ? where empno = ?")
             .set("1", 50, AdbaType.INTEGER)
             .set("2", idF, AdbaType.INTEGER)
             .apply(c -> { 
               if (c.getCount() != 1L) {
                 trans.setRollbackOnly();
                 throw new SqlException("updated wrong number of rows", null, null, -1, null, -1);
               }
               return c.getCount();
             })
             .onError(t -> t.printStackTrace())
             .submit();
     conn.catchErrors();
     conn.commitMaybeRollback(trans);
   }    
   ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
 }


