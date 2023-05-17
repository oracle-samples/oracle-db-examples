#!/bin/sh

# Copyright (c) 2019 by Oracle Corporation

# Generate awr reports in an instant client envrionment
# Put this script anywhere in your PATH, e.g. same place
# as you have sqlplus

# History:
#
# Modified Date         Comments
# bengsig  03-dec-2019   Uses getopt, can also generate ash
# bengsig  21-jun-2019   If last argument is a directory, generate file name
# bengsig   4-jun-2019   Added instance_start time column in list mode
# bengsig   2-may-2019   Added / or P marker for own root or pdb
# bengsig   1-may-2019   Created

helptext='-a awrrep : specify username/password@cstring for awr repository
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
for awr or dbid_inst_btime_etime.html for ash'

name=`basename $0`

usage='qry usage: '$name' [-h] -a awrrep [-d dbid] [-i inst#] [-f tstm] [-u/t tstm]
awr usage: '$name' -a awrrep -d dbid -i inst# bsnap esnap file/dir
ash usage: '$name' -a awrrep -d dbid -i inst# btime etime swidth file/dir'

options="Hha:d:i:f:u:t:"

help=no
until=''
from=''
inst=''
dbid=''

set -- `getopt -u -n $name -o $options -- "$@"`

while test $1 != '--'
do
  case $1 in 
    -u|-t) until=$2; shift; shift;
        ;;
    -f) from=$2; shift; shift;
        ;;
    -i) inst=$2; shift; shift;
        ;;
    -d) dbid=$2; shift; shift;
        ;;
    -a) repos=$2; shift; shift;
        ;;
    -H|-h) help=yes; shift;
        ;;
    esac;
done
shift

if test $help = yes
then
  echo -e "$usage"
  echo 
  echo -e "$helptext"
  exit 0
fi

if test x$repos = x
then
  echo -e "$usage"  1>&2
  exit 1
fi

# generate a file name for sqlplus
sql=`mktemp -p /tmp awrXXXXXXXXX.sql`
trap "rm -rf $sql" 0 int

cat > $sql <<END
whenever sqlerror exit failure
connect $repos
exit
END

# Don't read any login files
unset ORACLE_PATH
unset SQLPATH

if ! sqlplus -s -l $repos @$sql
then
  echo $name: Cannot connect using $repos 1>&2
  exit 2
fi

# OK, we can connect

# Get terminal size
cols=`stty size | awk '{print $2}'`
rows=`stty size | awk '{print $1}'`

# List of dbid's wanted?
if test x$dbid = x
then
  cat > $sql <<END
  set linesize $cols
  set pagesi $rows
  set feedback off 
  set serveroutput on

  variable myroot number;
  variable mypdbid number;
  variable myiscdb varchar2(3);
  declare
    -- find information from v$database about pdb/cdb
    ora942 exception; -- print own message if v$database is inaccessible
    pragma exception_init(ora942, -942);
  begin
    :myroot := 0;
    :mypdbid := 0;
    execute immediate 'select dbid, con_dbid, cdb from v\$database'
    into :myroot, :mypdbid, :myiscdb;
  exception
    when ora942 then
      dbms_output.put_line('PDB/CDB Information not available');
  end;
/

  whenever sqlerror exit failure
  column inst_list format a50 wrap
  select x.dbid
  , case when x.dbid = :myroot and :myiscdb = 'NO' then 'N'
         when x.dbid = :myroot then '/'
	 when x.dbid = :mypdbid then 'P'
	 else ' '
    end C
  , x.scount
  , y.inst_list
  from
    (
    select dbid
    , count(*) scount
    from dba_hist_snapshot
    group by dbid
    ) x
  join
    (
    select dbid
    , listagg(instance_number, ',') 
      within group (order by instance_number) inst_list
    from
    (
    select dbid
    , instance_number
    from dba_hist_snapshot
    group by dbid, instance_number
    )
    group by dbid
    ) y
  on x.dbid = y.dbid
  order by dbid;
  exit
END
  sqlplus -s -l $repos @$sql
  exit $?
fi

# dbid specified, but nothing else
if test -n "$dbid" -a -z "$inst" -a -z "$from" -a -z "$until" 
then
  cat > $sql <<END
  whenever sqlerror exit failure
  set linesize $cols
  set pagesi $rows
  set feedback off 

  column min_time format a18
  column max_time format a18
  column inst format 9999
  select instance_number inst
  , min(snap_id) min_snap
  , max(snap_id) max_snap
  , count(*) scount
  , to_char(min(end_interval_time),'YYYY.MM.DD"T"HH24:MI') min_time
  , to_char(max(end_interval_time),'YYYY.MM.DD"T"HH24:MI') max_time
  from dba_hist_snapshot
  where dbid = $dbid
  group by instance_number 
  order by instance_number;
  exit
END
  sqlplus -s -l $repos @$sql
  exit $?
fi

# Not only dbid specified

# No arguments, so do listing
if test $# = 0
then
  cat > $sql <<END
  whenever sqlerror exit failure
  set linesize $cols
  set pagesi $rows
  set feedback off 

  column snap_time format a20
  column instance_start format a20
  column inst format 9999
  column max_time format a20
  select instance_number inst
  , snap_id
  , to_char(end_interval_time,'YYYY.MM.DD"T"HH24:MI') snap_time
  , to_char(startup_time,'YYYY.MM.DD"T"HH24:MI') instance_start
  from dba_hist_snapshot
  where dbid = $dbid
END
  if test -n "$inst"
  then
    echo "and instance_number=$inst" >> $sql
  fi

  if test -n "$from" 
  then
    echo "and round(end_interval_time,'MI')" >> $sql
    echo ">= to_timestamp('$from','YYYY.MM.DD\"T\"HH24:MI')" >> $sql
  fi

  if test -n "$until" 
  then
    echo "and trunc(end_interval_time,'MI')" >> $sql
    echo "<= to_timestamp('$until','YYYY.MM.DD\"T\"HH24:MI')" >> $sql
  fi
  echo 'order by instance_number, snap_id;' >> $sql
  echo 'exit' >> $sql
  sqlplus -s -l $repos @$sql
  exit $?
fi

didit=no

# Instance and exactly three arguments, create awr
if test $# -eq 3 -a -n $inst
then
  # Which type is wanted
  if test -d "$3"
  then
    file=$3/${dbid}_${inst}_${1}_${2}.html
    echo "awr report will be written to $file"
  else
    file="$3"
  fi
  case `basename $file` in
    *.txt|*.text ) table=dbms_workload_repository.awr_report_text
      ;;
    *.html|*.htm ) table=dbms_workload_repository.awr_report_html
      cols=4000
      ;;
    *.*) table=dbms_workload_repository.awr_report_html
      echo 'awr report will by of type html'
      cols=4000
      ;;
    *)
      echo "awr report will be written to $3.html"
      cols=4000
      table=dbms_workload_repository.awr_report_html
      file=$3.html
      ;;
  esac
    
  cat > $sql <<END
  whenever sqlerror exit failure
  set linesize $cols
  set pagesi 9999
  set feedback off heading off termout off verify off trimspool on
  set trimspool on

  spool $file
  select * from table($table($dbid,$inst,$1,$2));
  spool off
  exit
END
  if sqlplus -s -l $repos @$sql
  then
    didit=yes
  else
    fail=$?
    if test `cat $file | wc -l` -ge $rows
    then
      less $file
    else
      cat $file
    fi
      
    exit $fail
  fi
fi


# Instance and exactly four arguments, create ash
if test $# -eq 4 -a -n $inst
then
  # Which type is wanted
  if test -d "$4"
  then
    file=$4/${dbid}_${inst}_${1}_${2}.html
    echo "ash report will be written to $file"
  else
    file="$4"
  fi
  case `basename $file` in
    *.txt|*.text ) table=dbms_workload_repository.ash_report_text
      ;;
    *.html|*.htm ) table=dbms_workload_repository.ash_report_html
      cols=4000
      ;;
    *.*) table=dbms_workload_repository.ash_report_html
      echo 'ash report will by of type html'
      cols=4000
      ;;
    *)
      echo "ash report will be written to $4.html"
      cols=4000
      table=dbms_workload_repository.ash_report_html
      file=$4.html
      ;;
  esac
    
  cat > $sql <<END
  whenever sqlerror exit failure
  set linesize $cols
  set pagesi 9999
  set feedback off heading off termout off verify off trimspool on
  set trimspool on

  spool $file
  select * from table($table($dbid,$inst
  ,to_date('$1','YYYY.MM.DD"T"HH24:MI')
  ,to_date('$2','YYYY.MM.DD"T"HH24:MI')
  , l_slot_width=>$3));
  spool off
  exit
END
  if sqlplus -s -l $repos @$sql
  then
    didit=yes
  else
    fail=$?
    if test `cat $file | wc -l` -ge $rows
    then
      less $file
    else
      cat $file
    fi
      
    exit $fail
  fi
fi

if test $didit != yes
then
  echo for awr, specify begin snap, end snap and file name 1>&2
  echo for ash, specify begin time, end time, slot width and file name 1>&2
  exit 1
fi
