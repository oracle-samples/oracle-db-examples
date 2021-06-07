# cx_Oracle Examples

This directory contains samples for [cx_Oracle][6].  Documentation is
[here][7].  A separate tutorial is [here][8].

1. The schemas and SQL objects that are referenced in the samples can be
   created by running the Python script [setup_samples.py][1]. The script
   requires SYSDBA privileges and will prompt for these credentials as well as
   the names of the schemas and edition that will be created, unless a number
   of environment variables are set as documented in the Python script
   [sample_env.py][2]. Run the script using the following command:

       python setup_samples.py

   Alternatively, the [SQL script][3] can be run directly via SQL\*Plus, which
   will always prompt for the names of the schemas and edition that will be
   created.

       sqlplus sys/syspassword@hostname/servicename @sql/setup_samples.sql

2. Run a Python script, for example:

        python query.py

3. After running cx_Oracle samples, the schemas and SQL objects can be
   dropped by running the Python script [drop_samples.py][4]. The script
   requires SYSDBA privileges and will prompt for these credentials as well as
   the names of the schemas and edition that will be dropped, unless a number
   of environment variables are set as documented in the Python script
   [sample_env.py][2]. Run the script using the following command:

       python drop_samples.py

   Alternatively, the [SQL script][5] can be run directly via SQL\*Plus, which
   will always prompt for the names of the schemas and edition that will be
   dropped.

       sqlplus sys/syspassword@hostname/servicename @sql/drop_samples.sql

[1]: https://github.com/oracle/python-cx_Oracle/blob/main/samples/setup_samples.py
[2]: https://github.com/oracle/python-cx_Oracle/blob/main/samples/sample_env.py
[3]: https://github.com/oracle/python-cx_Oracle/blob/main/samples/sql/setup_samples.sql
[4]: https://github.com/oracle/python-cx_Oracle/blob/main/samples/drop_samples.py
[5]: https://github.com/oracle/python-cx_Oracle/blob/main/samples/sql/drop_samples.sql
[6]: https://oracle.github.io/python-cx_Oracle/
[7]: http://cx-oracle.readthedocs.org/en/latest/index.html
[8]: https://oracle.github.io/python-cx_Oracle/samples/tutorial/Python-and-Oracle-Database-Scripting-for-the-Future.html
