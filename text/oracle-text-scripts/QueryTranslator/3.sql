select score(1) score, text from avtest where contains (text, parser.progrelax(
 'cat dog'
 ),1) > 0 order by score desc
/