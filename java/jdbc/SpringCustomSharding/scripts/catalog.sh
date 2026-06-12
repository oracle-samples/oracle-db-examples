# to be executed as oracle user on gsm-emea

gdsctl create shardcatalog \
  -repl DG \
  -region R_EMEA \
  -sharding USER \
  -user gsmcatuser/CHANGE_ME \
  -database '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.test)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=pcatalog)))'

gdsctl add gsm \
  -gsm sharddirector_emea \
  -listener 1521 \
  -pwd CHANGE_ME \
  -region R_EMEA \
  -catalog '(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=gsm-shard-emea.test)(PORT=1521))(CONNECT_DATA=(SERVICE_NAME=pcatalog)))'

gdsctl set gsm -gsm sharddirector_emea
gdsctl start gsm
gdsctl status gsm
gdsctl add region -region R_APAC
gdsctl add shardspace -shardspace S_EMEA
gdsctl add shardspace -shardspace S_APAC
gdsctl validate
gdsctl add invitedsubnet 192.168.8.0/24
gdsctl validate
