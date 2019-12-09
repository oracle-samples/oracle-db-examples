## Generating AWR or ASH reports using Oracle Client

When you are using a database client environment that only has an Oracle Client installation such as Instant Client, there is no immediate way to create awr or ash reports as the usual scripts in rdbms/admin under ORACLE_HOME in a full database installation aren't available.  Often, however, you do have the possibility to connect using sqlplus to a database using a login that provides access to one or more awr repositories.  If that is the case, you can create awr and ash reports using the dbms_workload_repository package.  Doing so, however, requires you to first query the repository for existing databases, instances and snapshots. This is effectively what the scripts like awrrpt.sql in rdbms/admin do. 

We have packed up this whole process in a single shell script that is using sqlplus to do the actual work. 

## Download and install of the "awr.sh" shell script

The script is a single, self-contained shell script.  You simply download it and put it somewhere in your PATH.  If you e.g. are using Instant Client, put it the same place where you have sqlplus.

## Requirements

Your environment variables need to be configured to allow database connections using sqlplus.  Also, you will need  to be able to connect to a database that holds an awr repository; if you connect using sqlplus, verify by running a query against dba_hist_snapshot. 

For the rest of this readme, it assumed that this is possible using system/manager@//awrhost/awr; you need to replace this with credentials to your database. An example usage of the script is to generate awr and ash reports from an ATP or ADW database, where you do not have access to the server. These cloud databases will be created with a user called "admin" and a password specified when you created the database using the cloud console. From the cloud console you can also get connect strings and download sqlnet wallets.  Once the wallet is installed in your client environment, you will have access to the admin account using a connection like admin/MyChosenPassword@database_tp which is what you must provide using the -a option of the awr.sh script.

## Usage

Simply call the script without any arguments to get a brief usage:

```
qry usage: awr.sh [-h] -a awrrep [-d dbid] [-i inst#] [-f tstm] [-u/t tstm]
awr usage: awr.sh -a awrrep -d dbid -i inst# bsnap esnap file/dir
ash usage: awr.sh -a awrrep -d dbid -i inst# btime etime swidth file/dir
```


As the output shows, the script really has three modes - a query mode used to provide information about available databases, instances and snapshots in the repository, and two generation modes to actually create an awr or an ash. The query mode is used when the last three or four arguments (bsnap esnap file, btime etime swidth file) are not provided.

Typing only the -h option, gives you a more detailed help:

```
-a awrrep : specify username/password@cstring for awr repository
-d dbid   : list snapshots for only this database
-i inst#  : list snapshots for only this instance
-f tstm   : limit listing from this timestamp
-u tstm   : limit listing until this timestamp
-t tstm   : limit listing to this timestamp

-a is compulsory

If -d is not specified, list all available databases
If only -d is specified, list first/last snapshots for that database

Format for timestamps are YYYY.MM.DDTHH24:MI, i.e. with "T" to
separate date from time, and with time in minute resolution

If -d and one or more of -i -f, -u/t are specified,
list all snapshots matching -i, -f, -u/t
The -u and -t options have identical purpose

If -d, -i and exactly three arguments are specified
generate awr for the chosen database and instance
covering the snapshot interval from bsnap to esnap
and write to the named file.

If -d, -i and exactly four arguments are specified
generate ash for the chosen database and instance
covering the time interval from btime to etime
with ash slots every swidth seconds and write to the
named file.

If the name of a directory is provided, an html formatted
file will be created named dbid_inst_bsnap_esnap.html
for awr or dbid_inst_btime_etime.html for ash
```

The options and their arguments must be put in the order shown and the -a option with its argument being the full connect string to your repository database must always be provided.  The various useful combinations of -d, -i, -f and -u are mentioned below.

## Query mode

To get a brief listing of all available databases in the repository, only give the -a option:

```
awr.sh -a system/manager@//awrhost/awr 

      DBID C     SCOUNT INST_LIST
---------- - ---------- --------------------------------------------------
   8521111          353 1
  20190404          280 1,2
  40763195           18 1,2
 169739606           67 1
 186457481           25 1
 222390028           12 1
 283265821          208 1
 313070952         1701 1,2,3,4,5,6,7

This shows a list of all databases, the total number of snapshots for each, and the list of instances.  The second column (C) will have a value if the database is your own database and it is either not a pdb (N), is a pdb (P) or is the root of a PDB (/).  A sample output is this:

      DBID C     SCOUNT INST_LIST
---------- - ---------- --------------------------------------------------
3370815010 P       1558 2,3,6,7,8
3951758934 /       1597 1,2,3,4,5,6,7,8
```

which shows that the first database is a PDB that has snapshots generated for instances 2,3,6,7,8 and the the second database is the root and that it has snapshots generated on all instances 1 until 8.

Next, you many want details about a specific database, which is done by providing the DBID of that database using the -d option:

```
awr.sh -a system/manager@//awrhost/awr -d 40763195

 INST   MIN_SNAP   MAX_SNAP     SCOUNT MIN_TIME           MAX_TIME
----- ---------- ---------- ---------- ------------------ ------------------
    1      11167      11175          9 2018.10.19T06:00   2018.10.19T10:00
    2      11167      11175          9 2018.10.19T06:00   2018.10.19T10:00
```

For each instance, the first and last snapshot ID, the number of snapshots and the snapshot time of those first/last snapshots are shown. Note that the time is with minute resolution and the there is a letter "T" to separate date part and time part. If you want to see all snapshots available for some instance of your chosen database, specify both -d and -i:

```
awr.sh -a system/manager@//awrhost/awr -d 40763195 -i 2

 INST    SNAP_ID SNAP_TIME
----- ---------- --------------------
    2      11167 2018.10.19T06:00
    2      11168 2018.10.19T06:30
    2      11169 2018.10.19T07:00
    2      11170 2018.10.19T07:30
    2      11171 2018.10.19T08:00
    2      11172 2018.10.19T08:30
    2      11173 2018.10.19T09:00
    2      11174 2018.10.19T09:30
    2      11175 2018.10.19T10:00
```

In this case, there are only 7 snapshots, if the list is longer, you can chose a part of it by specifying either or both of the -f and -u option.  They both take timestamps in the format shown in the list and specify respectively the first (-f means "from") and/or the last (-u mean "until") timestamp wanted.  Here is just one example:

```
awr.sh -a system/manager@//awrhost/awr -d 40763195 -i 2 -f 2018.10.19T07 -u 2018.10.19T09

 INST    SNAP_ID SNAP_TIME
----- ---------- --------------------
    2      11169 2018.10.19T07:00
    2      11170 2018.10.19T07:30
    2      11171 2018.10.19T08:00
    2      11172 2018.10.19T08:30
    2      11173 2018.10.19T09:00
```

You can also use either of -f and/or -u without -i in which case snapshot id's for all instances within the limits of -f and/or -u are listed.  Note that you don't actually need to include the minute part in the timestamps, you can also exclude T and the hour/minute.  Using only -f and a date a few days before current date is somewhat similar to what the usual scripts in rdbms/admin can do.

If you want to list all snapshots for all instances of some database, use an until date in the future or a very early from date such as -f 1314:03:18 which means to show everything after the day Jacque de Molay was burned to death.  If you find out why that particular date is interesting for me, I'll buy you a beer next time we meet.

## Awr creation mode

Once you know the dbid, instance number and the snapshot id's you are interested in for your awr, the script must be called with both -d and -i options and then with exactly three arguments being respectively the begin snapshot id, end snapshot id, and the file name where the awr report will be put.; the latter can include a directory part.

From the above, you can e.g. do:

```
awr.sh -a system/manager@//awrhost/awr -d 40763195 -i 2 11170 11172 myawr.txt
```

which will create a file named myawr.txt that contains a text format awr for the given database and instance over the snapshot interval 11170 until 11172.  If the name of the file has suffix .htm or .html, an html formated awr will be created; if the file name has no suffix, .html will be added.  If there are errors during creation of the awr, these will be shown as shown here:

```
awr.sh -a system/manager@//awrhost/awr -d 40763195 -i 2 11170 21172 myawr.html
  select * from table(dbms_workload_repository.awr_report_text(40763195,2,11170,21172))
                      *
ERROR at line 1:
ORA-20019: 21172 is not a valid snapshot ID.
ORA-06512: at "SYS.DBMS_SWRF_REPORT_INTERNAL", line 17518
ORA-06512: at "SYS.DBMS_SWRF_REPORT_INTERNAL", line 3129
ORA-06512: at "SYS.DBMS_WORKLOAD_REPOSITORY", line 1204
ORA-06512: at line 1
```

## Ash creation mode

Once you know the dbid and the instance number for which you are interested in an ash, call the script with those provided as -d and -i arguments and then subsequently exactly four arguments being respectively begin and end time, the slot width in seconds and the name of a file or directory, where the ash will be put.  As an example, if you execute

```
awr.sh -a system/manager@//awrhost/awr -d 2376680015 -i 3 2019.12.03T11:00 2019.12.03T12:00 60 ash11to12.html
```

an ash report covering the interval from 11:00 until 12:00 on 3-Dec-2019 with activity over time slots every 60 seconds will be put in the file specified as the last argument.
