select text from xmltest where contains (text,
'( 42 inpath (//attr/size) ) and
 ( Schuh inpath (//name[@lang="de\-de"]) )
 inpath (//attr)' )>0
/

select pk, text from xmltest where contains (text,
'Schuh INPATH (//attr[size="42" and @lang="de-DE"])')>0
/
