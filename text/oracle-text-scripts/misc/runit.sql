begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, '') 
select @starttime = getdate()
select @counter = 0
open @fcv
while 1=1
begin
  fetch next from @fcv into @theid 
  if @@fetch_status <> 0
    break
  select @counter = @counter + 1
end
close @fcv
select @finishtime = getdate()
insert into unisys.dbo.results2 values (@stream, datediff(ms, @starttime, @finishtime))
end

