REM
Rem  Copyright (c) 2000 by Oracle Corporation
Rem
Rem    NAME
Rem      txtsup_util.sql - Text index utility script
Rem
Rem    NOTES
Rem      Creates pl/sql package - txtsup_util - in the CTXSYS schema.
Rem      Users can call txtsup_util to find information about Text indexes.
Rem
Rem    USAGE
Rem      as CTXSYS, in SQL*Plus:
Rem        @txtsup_util
Rem
Rem      then as any user with a Text index, call
Rem
Rem      Typical usage example, from SQL*Plus:
Rem      set serveroutput on;
Rem      execute TXTSUP_UTIL.INDEX_PARAMETERS ('QUICK_TEXT');
Rem      execute TXTSUP_UTIL.INDEX_SIZE ('QUICK_TEXT');
Rem      execute TXTSUP_UTIL.GET_CREATE_INDEX_DDL('QUICK_TEXT');
Rem      execute TXTSUP_UTIL.GET_DROP_INDEX_DDL ('QUICK_TEXT');
Rem
Rem      For a fuller discussion of usage, see
Rem      <A HREF="/cgi-bin/webiv/do.pl/Get?WwwID=note:150453.1" >Note:150453.1</A> Strategy for creating Oracle Text Index
Rem
Rem    SEE ALSO
Rem
Rem    MODIFIED            (MM/DD/YY)
Rem    Radomir.Vranesevic   08/01/01  -  Added GET_CREATE_INDEX_DDL and GET_DROP_INDEX_DDL
Rem    Radomir.Vranesevic   06/25/01  -  Creation

set pagesize 1000
spool txtsup_util.log

CREATE OR REPLACE  PACKAGE        TXTSUP_UTIL  
AUTHID CURRENT_USER
IS
-- Calcualte space usage of Text Index
   PROCEDURE index_size (index_name IN VARCHAR2      /* Name of Text Index  */
                                                                              );

-- Dispaly all parameters of Text index
   PROCEDURE index_parameters (index_name IN VARCHAR2/* Name of Text Index  */
                                                                              );

-- Get DDL to recreate Text index
   PROCEDURE get_create_index_ddl (
      index_name IN VARCHAR2                         /* Name of Text Index  */
   );

-- Get DDL to drop Text index and preferences
   PROCEDURE get_drop_index_ddl (
      index_name IN VARCHAR2                         /* Name of Text Index  */
   );
END txtsup_util;
/
show errors


CREATE OR REPLACE PACKAGE BODY        TXTSUP_UTIL 
IS
   PROCEDURE index_size(index_name IN VARCHAR2 /* Name of Text Index  */ )
   IS
      total_blocks                NUMBER;
      total_bytes                 NUMBER;
      unused_blocks               NUMBER;
      unused_bytes                NUMBER;
      last_used_extent_file_id    NUMBER;
      last_used_extent_block_id   NUMBER;
      last_used_block             NUMBER;
      sum_total_blocks            NUMBER;
      sum_total_bytes             NUMBER;
      sum_unused_blocks           NUMBER;
      sum_unused_bytes            NUMBER;
      p_owner                     VARCHAR2(30);
      textline                    VARCHAR2(2000);
   BEGIN
      DBMS_OUTPUT.enable(buffer_size => 1000000);
      p_owner := USER();
      DBMS_OUTPUT.put_line(RPAD('=', 60, '='));
      DBMS_OUTPUT.put_line(' Space usage of Text Index:  ' || RPAD(p_owner || '.' || index_name, 25, ' '));
      DBMS_OUTPUT.put_line(RPAD('=', 60, '='));
      sum_total_blocks := 0;
      sum_total_bytes := 0;
      sum_unused_blocks := 0;
      sum_unused_bytes := 0;

      FOR i IN(SELECT   segment_type, segment_name, tablespace_name
               FROM     user_segments
               WHERE    segment_name LIKE 'DR$' || UPPER(index_name) || '%'
               AND      segment_type = 'TABLE'
                ORDER BY segment_name)
      LOOP
         DBMS_SPACE.unused_space(p_owner, i.segment_name, i.segment_type, total_blocks, total_bytes, unused_blocks, unused_bytes, last_used_extent_file_id, last_used_extent_block_id, last_used_block);
         sum_total_blocks := sum_total_blocks + total_blocks;
         sum_total_bytes := sum_total_bytes + total_bytes;
         sum_unused_blocks := sum_unused_blocks + unused_blocks;
         sum_unused_bytes := sum_unused_bytes + unused_bytes;
         DBMS_OUTPUT.put_line('TABLE_NAME             =    ' || i.segment_name);
         DBMS_OUTPUT.put_line('TABLESPACE NAME        =    ' || i.tablespace_name);
         DBMS_OUTPUT.put_line('ALLOCATED BLOCKS       =    ' || LPAD(total_blocks, 16));
         DBMS_OUTPUT.put_line('ALLOCATED BYTES        =    ' || TO_CHAR(total_bytes, '999,999,999,999') || ' (' || TO_CHAR(total_bytes / 1024 / 1024, '999,990.99') || 'Mb)');
         DBMS_OUTPUT.put_line('USED BLOCKS            =    ' || LPAD((total_blocks - unused_blocks), 16));
         DBMS_OUTPUT.put_line('USED BYTES             =    ' || TO_CHAR((total_bytes - unused_bytes), '999,999,999,999') || ' (' || TO_CHAR((total_bytes - unused_bytes) / 1024 / 1024, '999,990.99') || 'Mb)');
         DBMS_OUTPUT.put_line(RPAD('-', 60, '-'));
      END LOOP;

      -- LOB
      FOR j IN(SELECT   index_name, index_type, table_name, tablespace_name
               FROM     user_indexes
               WHERE    table_name LIKE 'NEWS'
                ORDER BY index_type)
      LOOP
         DBMS_SPACE.unused_space(p_owner, j.index_name, 'INDEX', total_blocks, total_bytes, unused_blocks, unused_bytes, last_used_extent_file_id, last_used_extent_block_id, last_used_block);
         sum_total_blocks := sum_total_blocks + total_blocks;
         sum_total_bytes := sum_total_bytes + total_bytes;
         sum_unused_blocks := sum_unused_blocks + unused_blocks;
         sum_unused_bytes := sum_unused_bytes + unused_bytes;
         DBMS_OUTPUT.put_line('INDEX_NAME             =    ' || j.index_name);
         DBMS_OUTPUT.put_line('INDEX_TYPE             =    ' || j.index_type);
         DBMS_OUTPUT.put_line('TABLE_NAME             =    ' || j.table_name);
         DBMS_OUTPUT.put_line('TABLESPACE NAME        =    ' || j.tablespace_name);
         DBMS_OUTPUT.put_line('ALLOCATED BLOCKS       =    ' || LPAD(total_blocks, 16));
         DBMS_OUTPUT.put_line('ALLOCATED BYTES        =    ' || TO_CHAR(total_bytes, '999,999,999,999') || ' (' || TO_CHAR(total_bytes / 1024 / 1024, '999,990.99') || 'Mb)');
         DBMS_OUTPUT.put_line('USED BLOCKS            =    ' || LPAD((total_blocks - unused_blocks), 16));
         DBMS_OUTPUT.put_line('USED BYTES             =    ' || TO_CHAR((total_bytes - unused_bytes), '999,999,999,999') || ' (' || TO_CHAR((total_bytes - unused_bytes) / 1024 / 1024, '999,990.99') || 'Mb)');
         DBMS_OUTPUT.put_line(RPAD('-', 60, '-'));
      END LOOP;

      DBMS_OUTPUT.put_line(RPAD('=', 60, '='));
      DBMS_OUTPUT.put_line('TOTAL ALLOCATED BLOCKS =    ' || LPAD(sum_total_blocks, 16));
      DBMS_OUTPUT.put_line('TOTAL ALLOCATED BYTES  =    ' || TO_CHAR(sum_total_bytes, '999,999,999,999') || ' (' || TO_CHAR(sum_total_bytes / 1024 / 1024, '999,990.99') || 'Mb)');
      DBMS_OUTPUT.put_line('TOTAL USED BLOCKS      =    ' || LPAD((sum_total_blocks - sum_unused_blocks), 16));
      DBMS_OUTPUT.put_line('TOTAL USED BYTES       =    ' || TO_CHAR((sum_total_bytes - sum_unused_bytes), '999,999,999,999') || ' (' || TO_CHAR((sum_total_bytes - sum_unused_bytes) / 1024 / 1024, '999,990.99') || 'Mb)');
  --  dbms_output.put_line('TOTAL UNUSED BLOCKS    =    ' || lpad(SUM_UNUSED_BLOCKS,16));
  --  dbms_output.put_line('TOTAL UNUSED BYTES     =    ' || to_char(SUM_UNUSED_BYTES,'999,999,999,999')||' ('||to_char(SUM_UNUSED_BYTES/1024/1024,'999,990.99')||'Mb)');
      DBMS_OUTPUT.put_line(RPAD('=', 60, '='));
   END index_size;

   PROCEDURE index_parameters(index_name IN VARCHAR2 /* Name of Text Index  */ )
   IS
      v_attributes   INTEGER;
   BEGIN
      DBMS_OUTPUT.enable(buffer_size => 1000000);
      DBMS_OUTPUT.put_line('***************************************************');
      DBMS_OUTPUT.put_line('* Atributes of Text Index:  ' || RPAD(index_name, 22, ' ') || '*');
      DBMS_OUTPUT.put_line('***************************************************');

      FOR i IN(SELECT   ixo_object
               FROM     ctx_user_index_objects
               WHERE    ixo_index_name = UPPER(index_name)
                ORDER BY ixo_class)
      LOOP
         DBMS_OUTPUT.put_line('==================================' || CHR(10) || LOWER(i.ixo_object));
         v_attributes := 0;

         FOR j IN(SELECT   ixv_attribute, ixv_value
                  FROM     ctx_user_index_values
                  WHERE    ixv_index_name = UPPER(index_name)
                  AND      ixv_object = i.ixo_object
                   ORDER BY ixv_attribute, ixv_value)
         LOOP
            v_attributes := v_attributes + 1;
            DBMS_OUTPUT.put_line('--- ' || RPAD(LOWER(j.ixv_attribute), 20, ' ') || j.ixv_value);
         END LOOP;

         IF v_attributes < 1
         THEN
            DBMS_OUTPUT.put_line('--- [no attributes]');
         END IF;
      END LOOP;

      DBMS_OUTPUT.put_line('***************************************************');
      DBMS_OUTPUT.put_line('* Atributes of Text Index:  ' || RPAD(index_name, 22, ' ') || '*');
      DBMS_OUTPUT.put_line('***************************************************');
   END index_parameters;

   PROCEDURE get_create_index_ddl(index_name IN VARCHAR2/* Name of Text Index  */)
   IS
      v_attributes           INTEGER;
      pref_name              VARCHAR2(2000);
      p_index_name           VARCHAR2(2000);
      index_name_length      INTEGER;
      index_sufix_length     INTEGER;
      user_ind_columns_rec   user_ind_columns%ROWTYPE;
      textline               VARCHAR2(2000);
      attrvalue              VARCHAR2(2000);
      section_name           VARCHAR2(30);
      tag                    VARCHAR2(30);
      visible                VARCHAR2(30);
   BEGIN
      DBMS_OUTPUT.enable(buffer_size => 1000000);
      index_name_length := LENGTH(index_name);
      index_sufix_length := 30 - index_name_length;
      DBMS_OUTPUT.put_line('--***************************************************');
      DBMS_OUTPUT.put_line('-- DDL to recreate Index:  ' || RPAD(index_name, 22, ' ') || '*');
      DBMS_OUTPUT.put_line('--***************************************************');
      DBMS_OUTPUT.put_line('BEGIN ');

      FOR i IN(SELECT   ixo_object, ixo_class
               FROM     ctx_user_index_objects
               WHERE    ixo_index_name = UPPER(index_name)
                ORDER BY ixo_class)
      LOOP
         pref_name := CHR(39) || UPPER(index_name) || '_' || UPPER(SUBSTR(i.ixo_class, 1, index_sufix_length)) || CHR(39);
         DBMS_OUTPUT.put_line('-- Create ' || UPPER(i.ixo_class) || ' : ' || pref_name);

         IF (i.ixo_class = 'STOPLIST')
         THEN
            textline := 'ctx_ddl.create_stoplist(' || pref_name || ',';
            textline := textline || CHR(39) || UPPER(i.ixo_object) || CHR(39) || ');';
            DBMS_OUTPUT.put_line(textline);
         ELSIF (i.ixo_class = 'SECTION_GROUP')
         THEN
            textline := 'ctx_ddl.create_section_group(' || pref_name || ',';
            textline := textline || CHR(39) || UPPER(i.ixo_object) || CHR(39) || ');';
            DBMS_OUTPUT.put_line(textline);
         ELSE
            textline := 'ctx_ddl.create_preference(' || pref_name || ',';
            textline := textline || CHR(39) || UPPER(i.ixo_object) || CHR(39) || ');';
            DBMS_OUTPUT.put_line(textline);
         END IF;

         v_attributes := 0;
         FOR j IN(SELECT   ixv_attribute, ixv_value
                  FROM     ctx_user_index_values
                  WHERE    ixv_index_name = UPPER(index_name)
                  AND      ixv_object = i.ixo_object
                   ORDER BY ixv_attribute, ixv_value)
         LOOP
            v_attributes := v_attributes + 1;

            IF i.ixo_class = 'STOPLIST' /* STOP LIST */
            THEN
               IF UPPER(j.ixv_attribute) = 'STOP_WORD'
               THEN
                  textline := 'ctx_ddl.add_stopword(' || pref_name || ',';
                  textline := textline || CHR(39) || j.ixv_value || CHR(39) || ');';
                  DBMS_OUTPUT.put_line(textline);
               ELSIF UPPER(j.ixv_attribute) = 'STOP_CLASS'
               THEN
                  textline := 'ctx_ddl.add_stopclass(' || pref_name || ',';
                  textline := textline || CHR(39) || j.ixv_value || CHR(39) || ');';
                  DBMS_OUTPUT.put_line(textline);
               ELSIF UPPER(j.ixv_attribute) = 'STOP_THEME'
               THEN
                  textline := 'ctx_ddl.add_stoptheme(' || pref_name || ',';
                  textline := textline || CHR(39) || j.ixv_value || CHR(39) || ');';
                  DBMS_OUTPUT.put_line(textline);
               END IF;
            ELSIF (i.ixo_class = 'SECTION_GROUP') /* SECTION_GROUP */
            THEN
               IF UPPER(j.ixv_attribute) = 'SPECIAL'
               THEN
                  textline := 'ctx_ddl.add_special_section(' || pref_name || ',';
                  textline := textline || CHR(39) || RTRIM(j.ixv_value, '::1:Y') || CHR(39) || ');';
                  DBMS_OUTPUT.put_line(textline);
               ELSIF UPPER(j.ixv_attribute) = 'FIELD'
               THEN
                  textline := 'ctx_ddl.add_field_section(' || pref_name || ',';
                  attrvalue := j.ixv_value;
                  section_name := SUBSTR(attrvalue, 1, INSTR(attrvalue, ':') - 1);
                  tag := SUBSTR(attrvalue, INSTR(attrvalue, ':', 1) + 1, (INSTR(attrvalue, ':', 1, 2) - INSTR(attrvalue, ':', 1) - 1));
                  visible := SUBSTR(attrvalue, INSTR(attrvalue, ':', 1, 3) + 1);
                  textline := textline || CHR(39) || section_name || CHR(39) || ',';
                  textline := textline || CHR(39) || tag || CHR(39) || ',';

                  IF visible = 'T'
                  THEN
                     textline := textline || 'TRUE );';
                  ELSE
                     textline := textline || 'FALSE );';
                  END IF;

                  DBMS_OUTPUT.put_line(textline);
               ELSIF UPPER(j.ixv_attribute) = 'ZONE'
               THEN
                  textline := 'ctx_ddl.add_zone_section(' || pref_name || ',';
                  attrvalue := j.ixv_value;
                  section_name := SUBSTR(attrvalue, 1, INSTR(attrvalue, ':') - 1);
                  tag := SUBSTR(attrvalue, INSTR(attrvalue, ':', 1) + 1, (INSTR(attrvalue, ':', 1, 2) - INSTR(attrvalue, ':', 1) - 1));
                  textline := textline || CHR(39) || section_name || CHR(39) || ',';
                  textline := textline || CHR(39) || tag || CHR(39) || ');';
                  DBMS_OUTPUT.put_line(textline);
               ELSIF UPPER(j.ixv_attribute) = 'STOP'
               THEN
                  textline := 'ctx_ddl.add_stop_section(' || pref_name || ',';
                  attrvalue := j.ixv_value;
                  section_name := SUBSTR(attrvalue, 1, INSTR(attrvalue, ':') - 1);
                  tag := SUBSTR(attrvalue, INSTR(attrvalue, ':', 1) + 1, (INSTR(attrvalue, ':', 1, 2) - INSTR(attrvalue, ':', 1) - 1));
                  textline := textline || CHR(39) || tag || CHR(39) || ');';
                  DBMS_OUTPUT.put_line(textline);
               END IF;
            ELSIF (i.ixo_class = 'STORAGE') /* STORAGE */
            THEN
               textline := 'ctx_ddl.set_attribute(' || pref_name || ',' || CHR(39) || UPPER(j.ixv_attribute) || CHR(39) || ',';
               DBMS_OUTPUT.put_line(textline);
               textline := CHR(39) || j.ixv_value || CHR(39) || ');';
               DBMS_OUTPUT.put_line(textline);
            ELSE                    /* ELSE if not STORAGE, STOPLICT, OR SECTION GROUP*/
               textline := 'ctx_ddl.set_attribute(' || pref_name || ',';
               textline := textline || CHR(39) || UPPER(j.ixv_attribute) || CHR(39) || ',';
               textline := textline || CHR(39) || j.ixv_value || CHR(39) || ');';
               DBMS_OUTPUT.put_line(textline);
            END IF;
         END LOOP;
         DBMS_OUTPUT.put_line(CHR(10));
      END LOOP;

      DBMS_OUTPUT.put_line('END; ');
      DBMS_OUTPUT.put_line('/ ');
      DBMS_OUTPUT.put_line(CHR(10));
      DBMS_OUTPUT.put_line('-- Create index command --');
      DBMS_OUTPUT.put_line(CHR(10));
      DBMS_OUTPUT.put_line('CREATE INDEX ' || index_name);
      p_index_name := index_name;
      SELECT   *
      INTO     user_ind_columns_rec
      FROM     user_ind_columns
      WHERE    index_name = UPPER(p_index_name)
      AND      column_position = 1;
      DBMS_OUTPUT.put_line('ON ' || user_ind_columns_rec.table_name || '(' || user_ind_columns_rec.column_name || ')');
      DBMS_OUTPUT.put_line('INDEXTYPE IS CTXSYS.CONTEXT');
      DBMS_OUTPUT.put_line('PARAMETERS(' || CHR(39));

      FOR n IN(SELECT   ixo_object, ixo_class
               FROM     ctx_user_index_objects
               WHERE    ixo_index_name = UPPER(index_name)
                ORDER BY ixo_class)
      LOOP
         pref_name := UPPER(index_name) || '_' || UPPER(SUBSTR(n.ixo_class, 1, index_sufix_length));

         IF UPPER(n.ixo_class) = 'SECTION_GROUP'
         THEN
            DBMS_OUTPUT.put_line(RPAD('SECTION GROUP', 30) || pref_name);
         ELSE
            DBMS_OUTPUT.put_line(RPAD(UPPER(n.ixo_class), 30) || pref_name);
         END IF;
      END LOOP;

      DBMS_OUTPUT.put_line('MEMORY 50M');
      DBMS_OUTPUT.put_line(CHR(39) || ');');
      DBMS_OUTPUT.put_line(CHR(10));
      DBMS_OUTPUT.put_line('--***************************************************');
      DBMS_OUTPUT.put_line('-- DDL to recreate Index:  ' || RPAD(index_name, 22, ' ') || '*');
      DBMS_OUTPUT.put_line('--***************************************************');
   END get_create_index_ddl;

   PROCEDURE get_drop_index_ddl(index_name IN VARCHAR2 /* Name of Text Index  */)
   IS
      v_attributes         INTEGER;
      pref_name            VARCHAR2(2000);
      index_name_length    INTEGER;
      index_sufix_length   INTEGER;
   BEGIN
      DBMS_OUTPUT.enable(buffer_size => 1000000);
      index_name_length := LENGTH(index_name);
      DBMS_OUTPUT.put_line('--***************************************************');
      DBMS_OUTPUT.put_line('-- DDL to drop Index:  ' || RPAD(index_name, 22, ' ') || '*');
      DBMS_OUTPUT.put_line('--***************************************************');
      DBMS_OUTPUT.put_line('BEGIN ');

      FOR i IN(SELECT   ixo_object, ixo_class
               FROM     ctx_user_index_objects
               WHERE    ixo_index_name = UPPER(index_name)
                ORDER BY ixo_class)
      LOOP
         index_sufix_length := 30 - index_name_length;
         pref_name := CHR(39) || UPPER(index_name) || '_' || UPPER(SUBSTR(i.ixo_class, 1, index_sufix_length)) || CHR(39);
   --    Dbms_Output.Put_Line('-- Begin create ' || upper(i.ixo_class) || ' preference :  ' || pref_name);
         IF (i.ixo_class = 'STOPLIST')
         THEN
            DBMS_OUTPUT.put_line('ctx_ddl.drop_stoplist(' || pref_name || ');');
         ELSIF (i.ixo_class = 'SECTION_GROUP')
         THEN
            DBMS_OUTPUT.put_line('ctx_ddl.drop_section_group(' || pref_name || ');');
         ELSE
            DBMS_OUTPUT.put_line('ctx_ddl.drop_preference(' || pref_name || ');');
         END IF;
      END LOOP;

      DBMS_OUTPUT.put_line('END; ');
      DBMS_OUTPUT.put_line('/ ');
      DBMS_OUTPUT.put_line(CHR(10));
      DBMS_OUTPUT.put_line('-- Drop index command --');
      DBMS_OUTPUT.put_line(CHR(10));
      DBMS_OUTPUT.put_line('DROP INDEX ' || index_name || ' ;');
      DBMS_OUTPUT.put_line('--***************************************************');
      DBMS_OUTPUT.put_line('-- DDL to drop Index:  ' || RPAD(index_name, 22, ' ') || '*');
      DBMS_OUTPUT.put_line('--***************************************************');
   END get_drop_index_ddl;
END txtsup_util;
/
show errors

drop public synonym txtsup_util;

create public synonym txtsup_util for txtsup_util;
grant execute on txtsup_util to public;
