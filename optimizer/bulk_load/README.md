<h2>Bulk Loading via External Table Examples</h2>

A couple of examples of bulk loading data into an Oracle database using external tables.

For full details, and the background behind the examples, check out the LINK Youtube web seminar. It explains how to load data in bulk into an Oracle Database. 

The examples were tested on Oracle Enterprise Linux and Oracle Database 12.1.0.2 but they should work on Oracle 11gR2 too.

It's easiest to use the scripts in an Oracle DBA user account, but this is not necessary as long as you have priviledges to create tables and Oracle DB directories. The scripts assume that you have created an empty "/home/oracle/direct" directory but you can change this by editing "01_dirs.sql" and "05_makedat.sh" to your chosen location. Note that 05_makedat.sh will delete some files from this directory, so make sure that it does not contain anything of value.

The scripts are intended to be executed in order, "01...", "02..." and so on. Example ".lst" output files are given so you can see what the "ins" scripts do when you run them.

DISCLAIMER:
   <br/>-- These scripts are provided for educational purposes only.
   <br/>-- They are NOT supported by Oracle World Wide Technical Support.
   <br/>-- The scripts have been tested and they appear to work as intended.
   <br/>-- You should always run scripts on a test instance.
   <br/>-- Note that they will DROP tables when they are executed.

