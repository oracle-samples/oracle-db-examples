A table function is a function that can be invoked in the FROM clause of a query, as if it were a table, hence the name. Use cases for table functions include the following:

Merge session-specific data with data from tables

You've got data, and lots of it sitting in tables. But in your session (and not in any tables), you have some data - and you need to "merge" these two sources together in an SQL statement. In other words, you need the set-oriented power of SQL to get some answers.

With the TABLE operator, you can accomplish precisely that.

Programmatically construct a dataset to be passed as rows and columns to the host environment

Your webpage needs to display some data in a nice neat report. That data is, however, far from neat. In fact, you need to execute procedural code to construct the dataset. Sure, you could construct the data, insert into a table, and then SELECT from the table.

But with a table function, you can deliver that data immediately to the webpage, without any need for non-query DML.

Create (what is in effect) a parameterized view

One of my favorites, and arises (for me) directly from my work on the PL/SQL Challenge. We have lots of different ranking reports, based on different materialized views (but all very similar in their columns and the way the data is computed). Used to be, we created something like 25 different interactive reports in Application Express.

Then, when facing the need to enhance each and every one of those, we stepped back and looked for ways to avoid this repetitive mess. The answer lay in a table function. Since you call a function in the FROM clause, you can pass parameters to the function and therefore to the query itself. That flexibility made it possible to replace those 25 different reports with just 1 report, built on that "parameterized view."

Improve performance of parallelized queries (pipelined table functions)

Many data warehouse applications rely on Parallel Query to greatly improve performance of massive ETL operations. But if you execute a table function in the FROM clause, that query will serialize (blocked by the call to the function). Unless, unless....you define that function a a pipelined function and enable it for parallel execution.

Reduce consumption of Process Global Area (pipelined table functions)

Collections (which are constructed and returned by "normal" table functions) can consume an  awful lot of PGA (Process Global Area). But if you define that table function as pipelined, PGA consumption becomes a non-issue.