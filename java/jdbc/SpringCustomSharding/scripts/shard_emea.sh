# to be executed as oracle user on gsm-emea

# EMEA_AT_EMEA
gdsctl add cdb -pwd CHANGE_ME \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.test)(PORT=1530))(CONNECT_DATA=(SERVICE_NAME=EMEA_AT_EMEA)))'

gdsctl add shard -pwd CHANGE_ME \
       -shardspace S_EMEA \
       -region R_EMEA \
       -cdb emea_at_emea \
       -deploy_as PRIMARY \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.test)(PORT=1530))(CONNECT_DATA=(SERVICE_NAME=pemea)))'

gdsctl validate
gdsctl deploy



# EMEA_AT_APAC
gdsctl add cdb -pwd CHANGE_ME \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-apac.test)(PORT=1530))(CONNECT_DATA=(SERVICE_NAME=EMEA_AT_APAC)))'

gdsctl add shard -pwd CHANGE_ME \
       -shardspace S_EMEA \
       -region R_APAC \
       -cdb emea_at_apac \
       -deploy_as ACTIVE_STANDBY \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-apac.test)(PORT=1530))(CONNECT_DATA=(SERVICE_NAME=pemea)))'

gdsctl validate
gdsctl deploy



gdsctl config shard -support
gdsctl config cdb
gdsctl instances
gdsctl databases

