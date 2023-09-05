# Oracle Text Scripts

I've been working with Oracle Text since it was created, in the days of Oracle 7 in the mid 1990s.

Over that time I've created a lot of scripts to test out or demonstrate various features of the product.

Since I'd like to retire in the not too distant future, I wanted to collect them together and make them publicly available.

Please note this is not a polished selection of sample files, it's more a snapshot of part of my hard disk.
I've tried to clean them up and make sure that where possible there are adequate comments in either the top of the .sql files, or in a README.txt file in the directory.

Some scripts work only in the very latest (23c) release, some illustrate obsolete features that are deprecated and/or no longer relevant. But the vast majority will work on all current and recent releases - 12.1, 12.2, 19c and 21c.

Most scripts are designed to be re-runnable, such that the first time you run them you may see errors as they attempt to drop objects which don't yet exist. Some scripts have the drop commands commented out - you'll need to uncomment them on subsequent runs.

Some scripts create users, some use an existing user, typically 'ROGER'. Passwords for SYS or SYSTEM are sometimes hard-coded, usually as 'oracle'. Any other passwords you might find are not in use on any current system :)  If you have a database with users called TESTUSER, USER1 or similar, I suggest you don't run any scripts without checking to see if they drop those users

If you have any questions, I'll be happy to try to answer them at roger.ford@oracle.com - or if I've retired, you can try roger.ford@gmail.com - I'm sure I'll still want to help out with technical questions or issues.