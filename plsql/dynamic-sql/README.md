PL/SQL makes it very easy to execute dynamic SQL statements, including DDL and PL/SQL blocks, through either:

Native Dynamic SQL
* EXECUTE IMMEDIATE
* OPEN FOR

and

DBMS_SQL, a comprehensive supplied package API to dynamic SQL operations. 

Generally, EXECUTE IMMEDIATE will handle almost all your dynamic SQL requirements. Consider using DBMS_SQL primarily for the most advanced requirements, such as method 4 dynamic SQL.
