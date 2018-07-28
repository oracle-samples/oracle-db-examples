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

package ReadMe;

import java.util.concurrent.CompletionStage;
import java.util.concurrent.ForkJoinPool;
import java.util.concurrent.TimeUnit;
import java.util.stream.Collector;
import jdk.incubator.sql2.AdbaType;
import jdk.incubator.sql2.DataSource;
import jdk.incubator.sql2.DataSourceFactory;
import jdk.incubator.sql2.Session;
import jdk.incubator.sql2.SqlException;
import jdk.incubator.sql2.TransactionCompletion;

/**
 *
 */
public class ReadMe {
  
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

}
