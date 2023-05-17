# Oracle Text Query Parser

Oracle Text provides a rich query syntax which enables powerful text searches.

However, this syntax isn&#39;t intended for use by inexperienced end-users. If you provide a simple search box in your application, you probably want users to be able to type &quot;Google-like&quot; searches into the box, and have your application convert that into something that Oracle Text understands.

For example if your user types "windows nt networking" they're probably interested in documents that include as many of those words as possible. You could put AND between each word to find documents with **all** of the terms (and risk missing documents that contain most but not all the terms), or you could put OR between each word to get documents that contain **any** of the terms (and potentially getting lots of irrelevant results). The ACCUM operator is best, because it ranks documents higher the more of the terms it finds. 

So you might decide to convert the user's query into something like
&quot;windows ACCUM nt ACCUM networking&quot;. But beware - &quot;NT&quot; is a reserved word, and needs to be escaped. So let&#39;s escape all words:
&quot;{windows} ACCUM {nt} ACCUM {networking}&quot;. That&#39;s fine - until you start introducing wild cards. Then you must escape only non-wildcarded searches:
&quot;win% ACCUM {nt} ACCUM {networking}&quot;. There are quite a few other &quot;gotchas&quot; that you might encounter along the way.

Then there&#39;s the issue of scoring. Given a query for &quot;oracle text query syntax&quot;, it would be nice if we could score a full phrase match higher than a hit where all four words are present but not in a phrase. And then perhaps lower than that would be a document where three of the four terms are present. 

[Progressive relaxation](./progrelax.html) helps you with this, but you need to code the &quot;progression&quot; yourself in most cases, which can be quite a task in itself.

To help with this, I&#39;ve developed a query parser which will take queries in a Google-like syntax, and convert them into Oracle Text queries. It&#39;s designed to be as flexible as possible, and will generate either simple queries or progressive relaxation queries. The input string will typically just be a string of words, such as &quot;oracle text query syntax&quot; but the grammar does allow for more complex expressions:

- ``word`` : score will be improved if word exists
- ``+word`` : word must exist (note Googe uses double quotes for this)
- ``-word`` : word CANNOT exist
- ``"phrase words"`` : words treated as phrase (may be preceded by + or -)
- ``fieldname:(expression)`` : find expression (which allows +,- and phrase as above) within &quot;fieldname&quot;.

So for example if I searched for

 ``+"oracle text" query +syntax -ctxcat``

Then the results would have to contain the phrase **"oracle text"** and the word **syntax**. Any documents mentioning **ctxcat** would be excluded from the results.

All the instructions are in the top of the file (see "Downloads" at the bottom of this blog entry). Please download the file, read the instructions, then
try it out by running "parser.pls" in either SQL*Plus or SQL Developer.

I am also uploading a test file "test.sql". You can run this and/or modify it to run your own tests or run against your own text index. test.sql is designed to be run from SQL*Plus and may not produce useful output in SQL Developer (or it may, I haven&#39;t tried it).
 
The code is used by a number of customers in production situations, and I have had good feedback for it. However it undoubtedly contains bugs (let me know if you find any) and I can't promise to fix them in a timely manner. You use this code at your own risk.

I welcome feedback, and am particularly interested in comments along the following lines:

* "The instructions are unclear - I couldn&#39;t figure out how to do XXX"
* "It didn&#39;t work in my environment" (please provide as many details as possible)
* "We can&#39;t use it in our application" (why not?)
* "It needs to support XXX feature"
* "It produced an invalid query output when I fed in XXXX"

## Downloads

[parser.pls](./parser.pls) main program file

[test.sql](./test.sql) for testing the package
