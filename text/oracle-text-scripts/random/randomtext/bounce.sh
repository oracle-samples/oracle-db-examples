sqlplus / as sysdba << EOT
shutdown immediate
quit
EOT
sudo sh -c 'sync ; echo 3 > /proc/sys/vm/drop_caches'
sqlplus / as sysdba << OET
startup
alter system set events '30580 trace name context forever, level 2';
quit
OET
