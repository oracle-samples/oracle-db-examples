Get a detailed list of database parameters and fix controls affected by optimizer_features_enable (OFE)

The script should be run on a test instance and it requires access to SYS.X$... tables and the ability to "alter session set optimizer_features_enable".

If the database has any Optimizer database parameters explicitly set, then this can mask reported differences.

The script will create some tables and drop them on completion, so you will be prompted for the name of schema where it is safe to do this.

Usage:
<br>1) Use SQLPLUS to connect to an account with access to SYS.X$ tables (usually SYS)
<br>2) @ofe

<a href="https://blogs.oracle.com/optimizer/entry/optimizer_feature_differences_for_oracle">See Optimizer blog for more details.</a>
