--
-- Using this as a trick to get DISPLAY_CURSOR to work on the new child
--
select *  FROM table(DBMS_XPLAN.DISPLAY_CURSOR(sql_id=>'g6y6gpnzww95b',cursor_child_no=>1))
/
