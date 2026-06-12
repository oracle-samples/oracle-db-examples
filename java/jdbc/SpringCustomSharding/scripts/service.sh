# to be executed as oracle user on gsm-emea

gdsctl add service -gdspool orasdb -service RO_SERVICE \
  -preferred_all \
  -locality LOCAL_ONLY -region_failover \
  -policy AUTOMATIC \
  -rlbgoal SERVICE_TIME \
  -clbgoal SHORT \
  -notification TRUE

gdsctl start service -service ro_service

gdsctl add service -gdspool orasdb -service RW_SERVICE \
  -preferred_all \
  -role PRIMARY \
  -locality ANYWHERE \
  -policy AUTOMATIC \
  -rlbgoal SERVICE_TIME \
  -clbgoal SHORT

gdsctl start service -service rw_service

gdsctl status service -service ro_service
gdsctl status service -service rw_service
