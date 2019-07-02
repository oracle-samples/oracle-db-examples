These are examples for the
[cx_Oracle driver](https://oracle.github.io/python-cx_Oracle).

Download and install from [PyPI](https://pypi.python.org/pypi/cx_Oracle) or
issue the command:

``python -m pip install cx_Oracle --upgrade``

[Documentation](http://cx-oracle.readthedocs.io/en/latest/index.html)
[Issues and questions](https://github.com/oracle/python-cx_Oracle/issues)


1. The schemas and SQL objects that are referenced in the samples can be
   created by running the Python script [SetupSamples.py][1]. The script
   requires SYSDBA privileges and will prompt for these credentials as well as
   the names of the schemas and edition that will be created, unless a number
   of environment variables are set as documented in the Python script
   [SampleEnv.py][2]. Run the script using the following command:

       python SetupSamples.py

   Alternatively, the [SQL script][3] can be run directly via SQL\*Plus, which
   will always prompt for the names of the schemas and edition that will be
   created.

       sqlplus sys/syspassword@hostname/servicename @sql/SetupSamples.sql

2. Run a Python script, for example:

        python Query.py

3. After running cx_Oracle samples, the schemas and SQL objects can be
   dropped by running the Python script [DropSamples.py][4]. The script
   requires SYSDBA privileges and will prompt for these credentials as well as
   the names of the schemas and edition that will be dropped, unless a number
   of environment variables are set as documented in the Python script
   [SampleEnv.py][2]. Run the script using the following command:

       python DropSamples.py

   Alternatively, the [SQL script][5] can be run directly via SQL\*Plus, which
   will always prompt for the names of the schemas and edition that will be
   dropped.

       sqlplus sys/syspassword@hostname/servicename @sql/DropSamples.sql

[1]: https://github.com/oracle/python-cx_Oracle/blob/master/samples/SetupSamples.py
[2]: https://github.com/oracle/python-cx_Oracle/blob/master/samples/SampleEnv.py
[3]: https://github.com/oracle/python-cx_Oracle/blob/master/samples/sql/SetupSamples.sql
[4]: https://github.com/oracle/python-cx_Oracle/blob/master/samples/DropSamples.py
[5]: https://github.com/oracle/python-cx_Oracle/blob/master/samples/sql/DropSamples.sql
