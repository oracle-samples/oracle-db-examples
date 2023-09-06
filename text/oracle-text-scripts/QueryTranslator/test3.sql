select score(0), text from avtest where contains (text, '
<query><textquery><progression>
<seq>(cat dog)</seq>
<seq>( NEAR((cat,dog)) )</seq>
<seq>((cat&dog)*10*10)&(NEAR((cat,dog)))</seq>
<seq>(cat&dog)</seq>
<seq>((dog)*10*10)&(&cat,dog)</seq>
</progression></textquery><score datatype="FLOAT"/></query>
', 0) > 0;

