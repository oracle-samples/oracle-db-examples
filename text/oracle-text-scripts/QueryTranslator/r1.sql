select rownum, sc, co from
   (SELECT /*+ CHOOSE DOMAIN_INDEX_SORT  INDEX(b BUGREP_INDEX )  */
        b.rptno, b.rptdate, b.subject, b.upd_date, b.status,
        b.portid, b.product_id, score(10) sc, b.utility_version,
        contains(b.bugtext, '(({PRODID-5}) AND {IMPLST-Y})*8', 11) co
        FROM sure_bug_bug_tbl b
        WHERE (contains(b.bugtext, '(({PRODID-5}) AND {IMPLST-Y})*8', 10) >0)
        ORDER BY score(10) DESC)
where rownum < 101
/
