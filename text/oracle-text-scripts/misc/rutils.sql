CREATE OR REPLACE PACKAGE RUtils AS
  -- Given an uncompressed textkey (from $K) returns the 14 byte RAW value
  -- as in $R
  FUNCTION KtoR(textkey IN CHAR)
    RETURN RAW;

  -- Given a 14 byte RAW value (from $R) returns the uncompressed textkey 
  -- as in $K
  FUNCTION RtoK(rawkey IN RAW)
    RETURN CHAR;

  -- Validates every rowid in $R by querying against the base table to
  -- check the rowid, also checks $K table.
  -- Output is done through UTIL_FILE using the location and file
  -- specified.  If any exceptions are raised from UTL_FILE, they are
  -- not caught by this routine, so ensure that you have the correct setup
  -- and permissions to write to the file before calling ValidateR.
  PROCEDURE ValidateR(index_name IN VARCHAR2,
                      base_table_name IN VARCHAR2,
                      output_location IN VARCHAR2,
                      output_filename IN VARCHAR2);
END RUtils;
/

show errors

CREATE OR REPLACE PACKAGE BODY RUtils AS
  DREK_IDS_PER_ROW INTEGER := 200000000;

  -- Given an uncompressed textkey (from $K) returns the 14 byte RAW value
  -- as in $R
  FUNCTION KtoR(textkey IN CHAR)
    RETURN RAW IS

    rawKey RAW(18) := UTL_RAW.CAST_TO_RAW(textkey);
  BEGIN
    RETURN UTL_RAW.CONCAT(
      UTL_ENCODE.BASE64_DECODE(UTL_RAW.SUBSTR(rawKey, 1, 16)),
      UTL_RAW.SUBSTR(rawKey, 17, 2));
  END KtoR;

  -- Given a 14 byte RAW value (from $R) returns the uncompressed textkey 
  -- as in $K
  FUNCTION RtoK(rawkey IN RAW)
    RETURN CHAR IS

  BEGIN
    RETURN 
        UTL_RAW.CAST_TO_VARCHAR2(UTL_ENCODE.BASE64_ENCODE(UTL_RAW.SUBSTR(rawKey, 1, 12))) ||
        UTL_RAW.CAST_TO_VARCHAR2(UTL_RAW.SUBSTR(rawKey, 13, 2));
  END RtoK;

  -- Validates every rowid in $R by querying against the base table to
  -- check the rowid, also checks $K table.
  -- Output is done through UTIL_FILE using the location and file
  -- specified.  If any exceptions are raised from UTL_FILE, they are
  -- not caught by this routine, so ensure that you have the correct setup
  -- and permissions to write to the file before calling ValidateR.
  PROCEDURE ValidateR(index_name IN VARCHAR2,
                      base_table_name IN VARCHAR2,
                      output_location IN VARCHAR2,
                      output_filename IN VARCHAR2) IS

    rCur SYS_REFCURSOR;
    row NUMBER;
    l BLOB;
    lobLength INTEGER;
    rVal RAW(14);
    realDocid INTEGER;
    realRowid ROWID;
    offset NUMBER;
    fileHandle utl_file.file_type;
  BEGIN

    fileHandle := utl_file.fopen(output_location, output_filename, 'w');
    utl_file.put_line(fileHandle, 'ValidateR report for index ' || index_name || ':');

    OPEN rCur FOR 
      'SELECT row_no, data ' ||
      '  FROM dr$' || index_name || '$r ' ||
      '  WHERE dbms_lob.getlength(data) > 0 ' ||
      '  ORDER BY row_no';
    LOOP
      FETCH rCur INTO row, l;
      EXIT WHEN rCur%NOTFOUND;

      lobLength := dbms_lob.getlength(l);
      utl_file.put_line(fileHandle, 'Row ' || row || 
        ': Lob length = ' || lobLength ||
        ' id_cnt = ' || lobLength / 14);

      FOR docid IN 1..(lobLength / 14) LOOP
        IF (mod(docid, 1000) = 0) THEN
          utl_file.put_line(fileHandle, 'Validating docid ' || docid, TRUE);
        END IF;

        SELECT (14 * (docid - 1)) + 1
          INTO offset
          FROM dual;
        rVal := dbms_lob.substr(l, 14, offset);
        realDocid := (row * DREK_IDS_PER_ROW) + docid;
        realRowid := RtoK(rVal);

        -- Now we can check realRowid against the base table
        DECLARE
          c NUMBER;
        BEGIN
          EXECUTE IMMEDIATE 
            'SELECT 1 FROM ' || base_table_name || ' WHERE rowid = :r '
            INTO c
            USING realRowid;
        EXCEPTION
          WHEN OTHERS THEN
            utl_file.put_line(fileHandle, 'Encountered error validating docid ' ||
              realDocid || ', rowid ' || realRowid || 
              ' against base table in row ' || row || ': ');
            utl_file.put_line(fileHandle, substr(sqlerrm, 1, 250));
        END;

        -- And against $K
        DECLARE
          d NUMBER;
        BEGIN
          EXECUTE IMMEDIATE
            'SELECT docid FROM dr$' || index_name || '$k' ||
            '  WHERE textkey = :r'
            INTO d
            USING realRowid;
        
          IF d != realDocid THEN
            utl_file.put_line(fileHandle, 'Encountered docid mismatch in $K: ' ||
              ' $R rowid = ' || realRowid ||
              ' $R docid = ' || realDocid ||
              ' $K docid = ' || d);
          END IF;
        EXCEPTION
          WHEN OTHERS THEN
            utl_file.put_line(fileHandle, 'Encountered error validating docid ' ||
              realDocid || ', rowid ' || realRowid || 
              ' against $K: ');
            utl_file.put_line(fileHandle, substr(sqlerrm, 1, 250));
        END;
      END LOOP;
    END LOOP;

    CLOSE rCur;
  EXCEPTION
    WHEN OTHERS THEN
      dbms_output.put_line('ValidateR caught exception:');
      dbms_output.put_line(substr(sqlerrm, 1, 250));
      utl_file.fclose(fileHandle);
      RAISE;
  END ValidateR;
END RUtils;
/

show errors
