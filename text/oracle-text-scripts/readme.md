# Oracle Text Scripts

I have been working with Oracle Text since the days of Oracle 7 in the mid-1990s. In that time I've acccumulated a large number of scripts, mostly intended to be run from SQL*Plus.

Some of them were designed to be passed on to customers to illustrate particular features of the product. Others were simply quick scripts I knocked up to test how a particular feature worked, or to investigate a bug. They therefore vary hugely in the amount of comments around the code.

As I intend to retire in the not too distant future, I wanted to make these scripts available for anyone working with Oracle Text. Probably the best way to use them is to download the lot, then use a recursive **grep** to look for the code feature or setting you're interested in. For example:

```
<copy>
find . -name \*.sql -exec grep -iH USER_DATASTORE {} \;
</copy>
```

(You can use the -r flag on some greps of course rather than using **find**)

In some directories I've put a readme file to explain the purpose of the scripts or files in that directory. In many I haven't. You'll find a lot of files called test.sql or similar, sorry - that's my lack of imagination showing. Those generally are the 'driver' files for the other scripts in the directory.

Some of these scripts are specific to newer versions like 23c, some refer to obsolete features, or use syntax or authorization mechanisms that worked in Oracle 10 or before (prior to 11g a lot of things, like user datastore procedures, had to be owned by the CTXSYS user).

Scripts are generally re-entrant - they attempt to drop all objects at the start. You'll see 'object does not exist' type errors on the first run.

Many scripts have connect operation which either use roger/roger or sys/oracle - you'll obviously need to change those to suit a working user in your database. Often they create new users - typically testuser/testuser, and they'll usually attempt to drop the user before creating it. So if you have a production database with a user called testuser, please don't run these scripts on it before checking them.

I can't promise any level of support, but if you have questions I'll do my best to answer them at roger.ford@oracle.com. If I've retired you can try the same name @gmail.com - I suspect I'll get a bit bored and will be more than happy to answer any questions or fiddle with some scripts after I'm retired.

Hope you find something useful in the collection