select score(0), text from avtest where contains (text, '
<query><textquery>cat dog rabbit<progression>
<seq><rewrite>transform((TOKENS, "{", "}", " "))</rewrite></seq>
<seq><rewrite>transform((TOKENS, "{", "}", "AND"))</rewrite></seq>
<seq><rewrite>transform((TOKENS, "{", "}", "OR"))</rewrite></seq>
</progression></textquery></query>',0) > 0
order by score(0) desc
/
