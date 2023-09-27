Errors in CTX_USER_INDEX_ERRORS (a view on CTXSYS.DR$INDEX_ERRORS) are deleted 
each time you run a new create index or sync index

This script creates a trigger on the table to copy errors to a persistant table 
so there is a permanent record
