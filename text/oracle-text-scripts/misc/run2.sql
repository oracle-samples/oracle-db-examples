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

select @stream = 2

begin
set @fcv = cursor fast_forward for
  select convert(varchar(50), id_obj) from unisys.dbo.news 
  where contains (text, 'BISOGNA') 
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
  where contains (text, 'CAMPO') 
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
  where contains (text, 'LUCE') 
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
  where contains (text, 'COSTA') 
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
  where contains (text, 'COMUNALE') 
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
  where contains (text, 'DAVANTI') 
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
  where contains (text, 'DONNE') 
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
  where contains (text, 'PARLARE') 
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
  where contains (text, 'BISOGNO') 
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
  where contains (text, 'GERMANIA') 
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
  where contains (text, 'PRENDERE') 
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
  where contains (text, 'SERIE') 
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
  where contains (text, 'IPOTESI') 
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
  where contains (text, 'CINEMA') 
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
  where contains (text, 'SERVIZI') 
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
  where contains (text, 'COMPAGNIA') 
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
  where contains (text, 'GRUPPI') 
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
  where contains (text, 'LAVORI') 
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
  where contains (text, 'MIGLIORE') 
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
  where contains (text, 'AUMENTO') 
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
  where contains (text, 'RAGGIUNTO') 
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
  where contains (text, 'PROBLEMA') 
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
  where contains (text, 'COLPO') 
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
  where contains (text, 'GIORNO') 
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
  where contains (text, 'PUNTA') 
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
  where contains (text, 'FORMAZIONE') 
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
  where contains (text, 'SCENA') 
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
  where contains (text, 'ULTIMA') 
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
  where contains (text, 'PAOLO') 
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
  where contains (text, 'OPERA') 
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
  where contains (text, 'ATTO') 
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
  where contains (text, 'BASTA') 
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

