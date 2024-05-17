The table DR$UNINDEXED is shared between all indexes
Over time it can get fragmented. Truncating it would potentially lose data,
so the file truncate_drunindexed.sql allows you to check there are no rows pending
(all indexes are sync'd) then locks the table and truncates it.
