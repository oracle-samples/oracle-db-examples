This directory contains examples dedicated the topic of the autonomous Oracle Optimizer.

Unless otherwise stated, I used <a href="http://www.oracle.com/technetwork/developer-tools/sqlcl/overview/index.html" name="SQLcl">SQLCL</a> to connect to the cloud database as follows:

<pre>
$ sql /nolog
SQL> set cloudconfig wallet_file.zip
SQL> connect adwcu1/password@dbname_high
</pre>

The directory *stats_on_load* contains a demonstration of how statistics are maintained for direct path INSERT, even if the target table contains rows.
