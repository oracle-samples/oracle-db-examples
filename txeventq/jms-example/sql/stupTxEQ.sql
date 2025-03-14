-- Create database user
create user aqjmsuser identified by Welcome_123#;
grant connect, resource to aqjmsuser;
grant execute on dbms_aq to aqjmsuser;
grant execute on dbms_aqadm to aqjmsuser;
grant execute on dbms_aqin to aqjmsuser;
grant unlimited tablespace to aqjmsuser;

-- Create Transactional Event Queue TOPIC_IN and TOPIC_OUT. Add a consumer Consumer1 for both
Declare
  subscriber sys.aq$_agent;
Begin
   subscriber := sys.aq$_agent('Consumer1', NULL, NULL);
   dbms_aqadm.create_transactional_event_queue(queue_name=>'aqjmsuser.TOPIC_IN', multiple_consumers=>TRUE);
   dbms_aqadm.start_queue('aqjmsuser.TOPIC_IN');
End;
/

Declare
  subscriber sys.aq$_agent;
Begin
   subscriber := sys.aq$_agent('Consumer1', NULL, NULL);
   dbms_aqadm.create_transactional_event_queue(queue_name=>'aqjmsuser.TOPIC_OUT', multiple_consumers=>TRUE);
   dbms_aqadm.start_queue('aqjmsuser.TOPIC_OUT');
End;
/