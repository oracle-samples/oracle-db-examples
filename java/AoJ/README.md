# AoJ: ADBA over JDBC


** 
Please note that although this material is valid and can be closed/branched, the work on the ADBA project has been terminated.
**

ADBA is Asynchronous Database Access, a non-blocking database access api that 
Oracle is proposing as a Java standard. ADBA was announced at 
[JavaOne 2016](https://static.rainfocus.com/oracle/oow16/sess/1461693351182001EmRq/ppt/CONF1578%2020160916.pdf) 
and presented again at 
[JavaOne 2017](http://www.oracle.com/technetwork/database/application-development/jdbc/con1491-3961036.pdf). 
The ADBA source is available for download from the 
[OpenJDK sandbox](http://hg.openjdk.java.net/jdk/sandbox/file/JDK-8188051-branch/src/jdk.incubator.adba/share/classes) 
as part of the OpenJDK project and the JavaDoc is available 
[here](http://cr.openjdk.java.net/~lancea/8188051/apidoc/jdk.incubator.adba-summary.html). 
You can get involved in the ADBA specification effort by following the 
[JDBC Expert Group mailing list](http://mail.openjdk.java.net/pipermail/jdbc-spec-discuss/). 

Reading a bunch of JavaDoc and interfaces can be interesting, but it is not nearly 
as engaging as having actual running code to play with. To that end, we have 
uploaded the beginnings of an implementation of ADBA running over standard JDBC, 
AoJ. AoJ is available for download from [GitHub](https://github.com/oracle/oracle-db-examples/tree/master/java/AoJ) 
under the Apache license. It should run with any reasonably standard compliant 
JDBC driver.

AoJ implements only a small part of ADBA, but it is enough to write interesting 
code. It provides partial implementations of ```DataSourceFactory```, ```DataSource```, 
```Session```, ```OperationGroup```, ```RowOperation```, ```CountOperation```, 
```Transaction``` and others. These implementations are not complete but there is 
enough there to write interesting database programs. The code that is there is 
untested, but it does work to some extent. The saving grace is that you can 
download the source and improve it: add new features, fix bugs, try out alternate 
implementations.

Oracle is not proposing AoJ as an open source project. However, because AoJ is 
released under the Apache license, the Java community can fork the code and create 
a true open source project with this upload as a base. Oracle developers may 
contribute when we have time, but this would have to be a Java community effort.

We could have held this code back and worked on it longer. Instead we thought it 
better to get it to the community as soon as we could. We hope that you agree.

## Building AoJ

AoJ and ADBA require JDK 9 or later. Download ADBA from the 
[OpenJDK sandbox](http://hg.openjdk.java.net/jdk/sandbox/file/JDK-8188051-branch/src/jdk.incubator.adba/share/classes).
It does not have any dependencies outside of Java SE 9. Download AoJ from 
[GitHub](https://github.com/oracle/oracle-db-examples/tree/master/java/AoJ).  Both 
are modularized so be sure to include the module-info.java files. AoJ depends on 
ADBA. The AoJ sample file depends on JUnit which is included with most IDEs but is 
also available [here](https://github.com/junit-team/junit4). 

To run the sample file you will need a SQL database and corresponding JDBC driver. AoJ 
has been run with [Oracle Database 12c](http://www.oracle.com/technetwork/database/enterprise-edition/downloads/index.html)
and [Oracle Database 12c JDBC](http://www.oracle.com/technetwork/database/application-development/jdbc/downloads/index.html),
but it should work with any reasonably standard compliant SQL database and JDBC
driver. The sample file uses the table 'emp' and 'dept'. So, you can create a user "testuser" and 'emp' and 'dept' tables using 
[JDBCSampleData.sql](https://github.com/oracle/oracle-db-examples/blob/master/java/jdbc/BasicSamples/JDBCSampleData.sql).

Start the database and make sure to create 'testuser' and needed tables using [JDBCSampleData.sql](https://github.com/oracle/oracle-db-examples/blob/master/java/jdbc/BasicSamples/JDBCSampleData.sql). Edit ```com.oracle.adbaoverjdbc.test.FirstLight.java```
and set the constant ```URL``` to an appropriate value. AoJ will pass this value
to ```java.sql.DriverManager.getSession```. If you are using a database other
than Oracle you should change the value of the constant ```TRIVIAL``` to some
very trivial ```SELECT``` query.

## Sample Code

The following test case should give you some idea of what AoJ can do. It  should
run with any JDBC driver connecting to a database with the 'testuser' schema. This is
the last test in ```com.oracle.adbaoverjdbc.test.FirstLight.java```. For an 
introduction to ADBA see the 
[JavaOne 2017 presentation](http://www.oracle.com/technetwork/database/application-development/jdbc/con1491-3961036.pdf). 


```
   public void readme(String url, String user, String password) {
   // get the AoJ DataSourceFactory
   DataSourceFactory factory = DataSourceFactory.newFactory("com.oracle.adbaoverjdbc.DataSourceFactory");
   // get a DataSource and a Session
   try (DataSource ds = factory.builder()
           .url(url)
           .username(user)
           .password(password)
           .build();
           Session conn = ds.getSession(t -> System.out.println("ERROR: " + t.getMessage()))) {
     // get a TransactionCompletion
     TransactionCompletion trans = conn.transactionCompletion();
     // select the EMPNO of CLARK
     CompletionStage<Integer> idF = conn.<Integer>rowOperation("select empno, ename from emp where ename = ? for update")
             .set("1", "CLARK", AdbaType.VARCHAR)
             .collect(Collector.of(
                     () -> new int[1], 
                     (a, r) -> {a[0] = r.at("empno").get(Integer.class); },
                     (l, r) -> null,
                     a -> a[0])
             )
             .submit()
             .getCompletionStage();
     // update CLARK to work in department 50
     conn.<Long>rowCountOperation("update emp set deptno = ? where empno = ?")
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
     
     conn.catchErrors();  // resume normal execution if there were any errors
     conn.commitMaybeRollback(trans); // commit (or rollback) the transaction
   }  
   // wait for the async tasks to complete before exiting  
   ForkJoinPool.commonPool().awaitQuiescence(1, TimeUnit.MINUTES);
 }
```

## AoJ Design Spec in 100 words or less

The methods called by the user thread create a network 
([DAG](https://en.wikipedia.org/wiki/Directed_acyclic_graph)) of 
```CompletableFuture```s. These ```CompleteableFuture```s asynchronously execute 
the synchronous JDBC calls and the result processing code provided by the user 
code. By default AoJ uses ```ForkJoinPool.commonPool()``` to execute 
```CompletableFuture```s but the user code can provide another ```Executor```.
When the ```Session``` is submitted the root of the ```CompleteableFuture```
network is completed triggering execution of the rest of the network.
