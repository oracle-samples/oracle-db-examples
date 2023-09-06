select count(*) from mydocs2 where contains (text, 'near( ( near((d,g)), near((b,f)) ) )' ) > 0
/
