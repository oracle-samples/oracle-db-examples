set echo on
exec :srch := rep.OTProgRelaxClob('cat-dog', 'avtestindex')
select score(0), text from avtest where contains (text, :srch, 0)>0 order by score(0) desc; 	
set echo off
