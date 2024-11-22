set echo on
--
select dbms_xdb.cfg_get() from dual
/
alter user xdb account lock
/
create or replace view DATABASE_SUMMARY as
select d.NAME, p.VALUE, i.HOST_NAME
from v$system_parameter p, v$database d, v$instance i
where p.name = 'service_names'
/
show errors
--
grant select on DATABASE_SUMMARY to public
/
alter session set current_schema = xdb
/

create or replace package XDB_CONFIGURATION
AUTHID CURRENT_USER
as
 procedure  setHTTPport (PORT_NUMBER number);
 procedure  setFTPport  (PORT_NUMBER number);
 function   getDatabaseSummary return xmltype;
 procedure  folderDatabaseSummary;
end XDB_CONFIGURATION;
/
show errors
--
create or replace package body XDB_CONFIGURATION as
--
FTP_XPATH   varchar2(256) := '/xdbconfig/sysconfig/protocolconfig/ftpconfig/ftp-port';
HTTP_XPATH  varchar2(256) := '/xdbconfig/sysconfig/protocolconfig/httpconfig/http-port';
--
function getDatabaseSummary
return XMLType
as 
  summary xmltype;
  dummy xmltype;
begin
  select dbms_xdb.cfg_get() 
  into dummy
  from dual;
  
  select xmlElement
         (
           "Database",
           XMLAttributes
           (
             x.NAME as "Name",
             extractValue(config,'/xdbconfig/sysconfig/protocolconfig/httpconfig/http-port') as "HTTP",
             extractValue(config,'/xdbconfig/sysconfig/protocolconfig/ftpconfig/ftp-port') as "FTP"
           ),
           xmlElement
           (
             "Services",
             (
               xmlForest(Value as "ServiceName")
             )
  	   ),
           xmlElement
           (
             "Hosts",
             (
               XMLForest(HOST_NAME as "HostName")
             )
	   )
         )
  into summary
  from SYS.DATABASE_SUMMARY x, (select dbms_xdb.cfg_get() config from dual);
  return summary;
end;
--
procedure folderDatabaseSummary
as
   result boolean;
   targetResource varchar2(256) := '/sys/databaseSummary.xml';

   xmlref ref xmltype;

begin

   begin
     dbms_xdb.deleteResource(targetResource,dbms_xdb.DELETE_FORCE);
   exception
     when others then
       null;
   end;

   select make_ref(DATABASE_SUMMARY,'DATABASE_SUMMARY')
   into xmlref 
   from DATABASE_SUMMARY;
   result := dbms_xdb.createResource(targetResource,xmlref);

   dbms_xdb.setAcl(targetResource,'/sys/acls/bootstrap_acl.xml');
end;
-- 
procedure setXDBport(PORT_XPATH varchar2, PORT_NUMBER number)
as
   config XMLType;
begin
   config := dbms_xdb.cfg_get();
   select updateXML(config, PORT_XPATH, PORT_NUMBER) 
   into config
   from dual;
   dbms_xdb.cfg_update(config);
   commit;
   dbms_xdb.cfg_refresh();
end;
--
-- Create the setHTTPport and setFTPport procudures
--
procedure setHTTPport (PORT_NUMBER number)
as
begin
  setXDBport(HTTP_XPATH || '/text()', PORT_NUMBER);
end;
--
procedure setFTPport(PORT_NUMBER number)
as
begin
  setXDBport(FTP_XPATH || '/text()', PORT_NUMBER);
end;
--
end XDB_CONFIGURATION;
/
show errors
--
create or replace view DATABASE_SUMMARY of xmltype
with object id 
(
'DATABASE_SUMMARY'
) 
as select xdb_configuration.getDatabaseSummary() from dual
/
show errors
--
alter package XDB_CONFIGURATION compile
/
show errors
--
alter view DATABASE_SUMMARY compile
/
show errors
--
grant select on DATABASE_SUMMARY to public
/
