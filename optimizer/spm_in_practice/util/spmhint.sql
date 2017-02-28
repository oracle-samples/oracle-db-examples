REM
REM Show the outline hints for SQL plan baseline
REM

column hint format a100

SELECT  extractValue(value(h),'.') AS hint
FROM    sys.sqlobj$plan od,
        TABLE(xmlsequence(
          extract(xmltype(od.other_xml),'/*/outline_data/hint'))) h
WHERE od.other_xml is not null
AND   (signature,category,obj_type,plan_id) = (select signature,
                             category,
                             obj_type,
                             plan_id
                      from   sys.sqlobj$ so
                      where so.name = '&plan_name');
