DECLARE
            procedure hwf_proc_json_oracle
			IS
			  v_banner varchar2(100);
			  plsql_block varchar2(2000);
			  metadata varchar2(1000);
			  i integer;
			  indx_1 varchar2(1000);
			  indx_2 varchar2(1000);
			  indx_3 varchar2(1000);
			BEGIN
--			  metadata := '''{"versionColumn":{"name":"VERSION", "method" : "UUID"},
--			                             "lastModifiedColumn":{"name":"LAST_MODIFIED"},
--			                             "creationTimeColumn":{"name":"CREATED_ON"}}''';
			  plsql_block := 'declare c soda_collection_t; m varchar2(1000);' ||
			                 'begin ' ||
			                 'm := ' || metadata || ';' ||
-- 			                 'c:= dbms_soda.create_collection(''DOCUMENTCOLLECTION'', m);' ||
			                 'c:= dbms_soda.create_collection(''DOCUMENTCOLLECTION'');' ||
			                 'end;';
			  indx_1 := 'declare c soda_collection_t; s NUMBER;' ||
			  			'begin '||
		                'c := DBMS_SODA.open_collection(''DOCUMENTCOLLECTION'');' ||
		                's := c.create_index(''{"name"   : "DCTASKID_I", "fields" : [{"path"     : "taskId"}]}'');' ||
		                'end;';
			  indx_2 := 'declare c soda_collection_t; s NUMBER;' ||
			  			'begin '||
		                'c := DBMS_SODA.open_collection(''DOCUMENTCOLLECTION'');' ||
		                's := c.create_index(''{"name"   : "DCPROCID_I", "fields" : [{"path"     : "processInstanceId"}]}'');' ||
		                'end;';
			  indx_3 := 'declare c soda_collection_t; s NUMBER;' ||
			  			'begin '||
		                'c := DBMS_SODA.open_collection(''DOCUMENTCOLLECTION'');' || 			  
		                's := c.create_index(''{"name"   : "DCPROCIDTASKID_I", "fields" : [{"path" : "processInstanceId"},{"path" : "taskId"}]}'');' ||
		                'end;';
			  SELECT BANNER into v_banner FROM V$VERSION where BANNER like 'Oracle Database%';
			  IF ( v_banner like '%18c%' OR v_banner like '%19c%' OR v_banner like '%20c%' OR v_banner like '%21c%')  THEN
			     
			      SELECT COUNT(*) INTO i FROM user_tables WHERE table_name = 'DOCUMENTCOLLECTION';
			      IF i = 0 THEN
			      	execute immediate plsql_block;
			      END IF;
			      SELECT COUNT(*) INTO i FROM user_indexes WHERE index_name = 'DCJSON_I';
    			  IF i = 0 THEN
			      	execute immediate 'create search index "DCJSON_I" on DOCUMENTCOLLECTION ("JSON_DOCUMENT") for json parameters(''sync( every "freq=secondly;interval=5") search_on text_value dataguide off'')';
			  	  END IF;
			  	  SELECT COUNT(*) INTO i FROM user_indexes WHERE index_name = 'DCTASKID_I';	
                  IF i = 0 THEN
			  	  	execute immediate  indx_1;
			  	  END IF;
			  	  SELECT COUNT(*) INTO i FROM user_indexes WHERE index_name = 'DCPROCID_I';
                  IF i = 0 THEN
			  	  	execute immediate  indx_2;
			  	  END IF;
			  	  SELECT COUNT(*) INTO i FROM user_indexes WHERE index_name = 'DCPROCIDTASKID_I';
                  IF i = 0 THEN
			  	  	execute immediate  indx_3;
			  	  END IF;
			  END IF;
			END hwf_proc_json_oracle;
			begin
			  hwf_proc_json_oracle;
			end;
