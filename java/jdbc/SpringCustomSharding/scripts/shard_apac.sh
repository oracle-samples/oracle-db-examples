# to be executed as oracle user on gsm-emea

# APAC_AT_APAC
gdsctl add cdb -pwd CHANGE_ME \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-apac.test)(PORT=1531))(CONNECT_DATA=(SERVICE_NAME=APAC_AT_APAC)))'

gdsctl add shard -pwd CHANGE_ME \
       -shardspace S_APAC \
       -region R_APAC \
       -cdb apac_at_apac \
       -deploy_as PRIMARY \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-apac.test)(PORT=1531))(CONNECT_DATA=(SERVICE_NAME=papac)))'

gdsctl validate
gdsctl deploy



# APAC_AT_EMEA
gdsctl add cdb -pwd CHANGE_ME \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.test)(PORT=1531))(CONNECT_DATA=(SERVICE_NAME=APAC_AT_EMEA)))'

gdsctl add shard -pwd CHANGE_ME \
       -shardspace S_APAC \
       -region R_EMEA \
       -cdb apac_at_emea \
       -deploy_as ACTIVE_STANDBY \
       -connect '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.test)(PORT=1531))(CONNECT_DATA=(SERVICE_NAME=papac)))'

gdsctl validate
gdsctl deploy



gdsctl config shard -support
gdsctl config cdb
gdsctl instances
gdsctl databases
