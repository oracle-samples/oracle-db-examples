break on profile_name
column profile_name format a30
column hint format a100
set linesize 200
set pagesize 1000
set trims on

SELECT  dspa.profile_name, extractValue(value(h),'.') AS hint
FROM    DBMSHSXP_SQL_PROFILE_ATTR dspa,
        TABLE(xmlsequence(
          extract(xmltype(dspa.comp_data),'/outline_data/hint'))) h;

