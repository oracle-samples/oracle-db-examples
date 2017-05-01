@show_prof

accept profile_name prompt 'Enter profile name : '

EXEC DBMS_SQLTUNE.ALTER_SQL_PROFILE ( name            =>  '&profile_name',   -
                                      attribute_name  =>  'STATUS', -
                                      value           =>  'DISABLED');
