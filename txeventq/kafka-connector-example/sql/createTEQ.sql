exec sys.dbms_aqadm.create_transactional_event_queue(queue_name=>'TEQ', multiple_consumers => TRUE); 
exec sys.dbms_aqadm.set_queue_parameter('TEQ', 'SHARD_NUM', 10);
exec sys.dbms_aqadm.set_queue_parameter('TEQ', 'STICKY_DEQUEUE', 1);
exec sys.dbms_aqadm.set_queue_parameter('TEQ', 'KEY_BASED_ENQUEUE', 2);
exec sys.dbms_aqadm.start_queue('TEQ');
exec sys.DBMS_AQADM.ADD_SUBSCRIBER('TEQ', SYS.AQ$_AGENT('SUB1', NULL, 0)) ;
