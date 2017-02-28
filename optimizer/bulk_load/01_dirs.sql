--
--
-- This script points to directories on the file system.
-- You can modify it to poing where you like, but
-- make sure that the physical directory exists on the
-- file system and that it is readable by the "oracle"
-- operating system user.
--
--
CREATE OR REPLACE DIRECTORY data_dir AS '/home/oracle/direct';
CREATE OR REPLACE DIRECTORY bad_dir AS '/home/oracle/direct';
CREATE OR REPLACE DIRECTORY log_dir AS '/home/oracle/direct';
