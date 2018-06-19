This directory contains examples of fine-grained cursor invalidation.

The test.sql is provided to give you ideas on how you can try this feature out for yourself. 

They are in quite a raw state because I originally wrote the examples for my own benefit to explore the boundaries of this feature. In particular, there is a mixture of some DDL that *will* allow SQL statements to use rolling invalidation and some DDL will not. Some of the PROMPT comments may be incorrect now because the test was created before Oracle Database 12c R2 was released.

### Note

The example here was run on Oracle Database 12c Release 2.

The test case drops tables T1 and T2.

### DISCLAIMER

*  These scripts are provided for educational purposes only.
*  They are NOT supported by Oracle World Wide Technical Support.
*  The scripts have been tested and they appear to work as intended.
*  You should always run scripts on a test instance.

### WARNING

*  These scripts drop and create tables. For use on test databases
