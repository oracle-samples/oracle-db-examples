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

select @stream = 3

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'CORSO') 
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
  where contains (text, 'TECNICO') 
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
  where contains (text, 'PARTI') 
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
  where contains (text, 'LETTO') 
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
  where contains (text, 'GIOCO') 
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
  where contains (text, 'DIVERSE') 
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
  where contains (text, 'MAGGIORANZA') 
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
  where contains (text, 'FACCIA') 
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
  where contains (text, 'DICEMBRE') 
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
  where contains (text, 'METTERE') 
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
  where contains (text, 'CORSA') 
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
  where contains (text, 'INSOMMA') 
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
  where contains (text, 'TORINESE') 
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
  where contains (text, 'SCELTA') 
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
  where contains (text, 'POSTI') 
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
  where contains (text, 'LASCIATO') 
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
  where contains (text, 'CIOÈ') 
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
  where contains (text, 'FEBBRAIO') 
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
  where contains (text, 'OPERAZIONE') 
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
  where contains (text, 'DATA') 
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
  where contains (text, 'STRADA') 
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
  where contains (text, 'BAMBINI') 
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
  where contains (text, 'POSSIBILITÀ') 
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
  where contains (text, 'SICURO') 
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
  where contains (text, 'LEADER') 
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
  where contains (text, 'EUROPEO') 
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
  where contains (text, 'CARLO') 
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
  where contains (text, 'RETE') 
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
  where contains (text, 'RISPONDE') 
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
  where contains (text, 'FRONTE') 
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
  where contains (text, 'PREZZO') 
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
  where contains (text, 'FIGLI') 
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

