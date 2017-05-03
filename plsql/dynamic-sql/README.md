PL/SQL makes it very easy to execute dynamic SQL statements, including DDL and PL/SQL blocks, through either:

Native Dynamic SQL
* EXECUTE IMMEDIATE
* OPEN FOR

and

DBMS_SQL, a comprehensive supplied package API to dynamic SQL operations. 

Generally, `EXECUTE IMMEDIATE` will handle almost all your dynamic SQL requirements. Consider using `DBMS_SQL` primarily for the most advanced requirements, such as method 4 dynamic SQL. See below for more details on different dynamic SQL methods.

Method 1 - DDL or non-query DML without bind variables

    EXECUTE IMMEDIATE string

Method 2 - Non-query DML with fixed number of bind variables

    EXECUTE IMMEDIATE string USING 

Method 3 - Query with fixed number of expressions in the select list and fixed number of bind variables

    EXECUTE IMMEDIATE string USING ... INTO

Method 4 - Query with dynamic number of expressions in select list or DML with dynamic number of bind variables.

    DBMS_SQL is usually the best path to a solution.
