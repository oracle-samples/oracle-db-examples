dbms_output is useful for debugging or testing PL/SQL procedures.

However it has a major limitation that it saves all output up until
the procedure completes.

This exercise was to create a 'streaming' version of DBMS_OUTPUT
which writes in real time.

It consists of two parts, a replacement for the DBMS_OUTPUT package,
and a perl listener that actually outputs the real-time messages.
