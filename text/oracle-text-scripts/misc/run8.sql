SET NOCOUNT ON
begin
declare @searchterm varchar(255)

declare @counter int
declare @limit int
declare @fcv cursor
declare @theid varchar(50)
declare @starttime datetime
declare @finishtime datetime
declare @stream int

end

select @stream = 8

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'STUDIO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'USCITA') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'NAPOLI') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'MATTINA') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'INGRESSO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'FACENDO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'STAVA') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'GENNAIO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'PICCOLO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'PIETRO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'UNITÀ') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'CHIEDERE') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'AMMINISTRAZIONE') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'CERTO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'TROVATO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'SULL') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'NOME') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'SOSTIENE') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'SPALLE') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'PAGINE') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'ALLORA') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'LAVORO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'ESEMPIO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'ITALIANA') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'COLLABORAZIONE') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'FACILE') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'AMERICA') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'CHIESTO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'NERO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'GOVERNO') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'DIFESA') 
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

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'DECISO') 
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

