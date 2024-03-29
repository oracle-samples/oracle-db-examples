-- turn off special meaning of ampersand:
set define off

drop table docs;

create table docs (id number primary key, text varchar2(4000));

insert into docs values (1, '
<html>
  <head>
    <title>Test Document</title>
  </head>
  <body>
    <h1>A Document for Testing</h1>
This is a document about dogs.
<p>&nbsp;<br> 
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
There are several mentions of dogs in this document.
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
The domestic dog (Canis lupus familiaris)[2][3] is the 18-31,000 year old descendant of a now extinct European Wolf,[4] and a member of the Canidae family of the mammalian order Carnivora. The term "domestic dog" is generally used for both domesticated and feral varieties. The dog was the first domesticated animal[5][6] and has been the most widely kept working, hunting, and pet animal in human history.[citation needed] The word "dog" can also refer to the male of a canine species,[7] as opposed to the word "bitch" which refers to the female of the species.
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
Recent studies of "well-preserved remains of a dog-like canid from the Razboinichya Cave" in the Altai Mountains of southern Siberia concluded that a particular instance of early wolf domestication approximately 33,000 years ago did not result in modern dog lineages, possibly because of climate disruption during the Last Glacial Maximum.[5][8] The authors postulate that at least several such incipient events have occurred. A study of fossil dogs and wolves in Belgium, Ukraine, and Russia tentatively dates domestication from 14,000 years ago to more than 31,700 years ago.[9] Another recent study has found support for claims of dog domestication between 14,000 and 16,000 years ago, with a range between 9,000 and 34,000 years ago, depending on mutation rate assumptions.[10] Dogs'' value to early human hunter-gatherers led to them quickly becoming ubiquitous across world cultures. Dogs perform many roles for people, such as hunting, herding, pulling loads, protection, assisting police and military, companionship, and, more recently, aiding handicapped individuals. This impact on human society has given them the nickname "man''s best friend" in the Western world. In some cultures, however, dogs are also a source of meat.[11][12] In 2001, there were estimated to be 400 million dogs in the world.[13]
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
<p>&nbsp;<br>
Most breeds of dog are at most a few hundred years old, having been artificially selected for particular morphologies and behaviors by people for specific functional roles. Through this selective breeding, the dog has developed into hundreds of varied breeds, and shows more behavioral and morphological variation than any other land mammal.[14] For example, height measured to the withers ranges from 15.2 centimetres (6.0 in) in the Chihuahua to about 76 cm (30 in) in the Irish Wolfhound; color varies from white through grays (usually called "blue") to black, and browns from light (tan) to dark ("red" or "chocolate") in a wide variation of patterns; coats can be short or long, coarse-haired to wool-like, straight, curly, or smooth.[15] It is common for most breeds to shed this coat.
  </body>
</html>
');

create index docsindex on docs(text) indextype is ctxsys.context;

set serverout on size 1000000

declare
  v_buff clob;
begin
  dbms_lob.createtemporary( v_buff, true );
  for c in ( select id from docs where contains( text, 'dog%' ) > 0 ) loop
     ctx_doc.markup ( 
        index_name => 'DOCSINDEX', 
        textkey    => to_char( c.id ), 
        text_query => 'dog%', 
        restab     => v_buff, 
        plaintext  => false,
        tagset     => 'HTML_NAVIGATE' );
    dbms_output.put_line( v_buff );
  end loop;
end;
/

