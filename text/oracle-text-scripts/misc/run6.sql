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

select @stream = 6

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'COMUNQUE') 
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
  where contains (text, 'PIENO') 
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
  where contains (text, 'VUOL') 
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
  where contains (text, 'PERIODO') 
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
  where contains (text, 'VERITÀ') 
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
  where contains (text, 'SAPERE') 
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
  where contains (text, 'VIENE') 
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
  where contains (text, 'PADRE') 
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
  where contains (text, 'ITALIANO') 
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
  where contains (text, 'AMBIENTE') 
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
  where contains (text, 'TEMA') 
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
  where contains (text, 'PARTIRE') 
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
  where contains (text, 'DIFFICOLTÀ') 
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
  where contains (text, 'POSIZIONE') 
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
  where contains (text, 'PIANO') 
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
  where contains (text, 'SEMPLICE') 
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
  where contains (text, 'ALTO') 
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
  where contains (text, 'MANO') 
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
  where contains (text, 'OTTOBRE') 
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
  where contains (text, 'PERSONALE') 
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
  where contains (text, 'SEGUITO') 
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
  where contains (text, 'MANI') 
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
  where contains (text, 'SPIEGATO') 
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
  where contains (text, 'SOLE') 
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
  where contains (text, 'UNIONE') 
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
  where contains (text, 'ATTENZIONE') 
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
  where contains (text, 'FARSI') 
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
  where contains (text, 'OTTENERE') 
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
  where contains (text, 'CARCERE') 
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
  where contains (text, 'AUTORITÀ') 
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
  where contains (text, 'SERGIO') 
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
  where contains (text, 'CHIUSO') 
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

