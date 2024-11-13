use CurrencyRate
go

-- ====================
-- every day from daily https://www.cbar.az/currencies/16.07.2023.xml
-- ====================
create or alter proc cur.GetExchangeRateAZN
(
  @Date date = null
, @UserId int = -1
)
as
begin
 set nocount on;
  begin transaction CurrencyAZN
  begin try
 
  set @Date = isnull(@Date, getdate())
  declare @Dates as table(x date)
  insert into @Dates
  select @Date

  declare @src varchar(255), @desc varchar(255), @step int = 0; 
  declare @hr int, @objectId int, @status int, @dayOfWeek int, @isUpdated bit;
  declare @out as table(isUpdated int);

  exec @hr = sp_OACreate 'MSXML2.ServerXMLHTTP', @objectId out
  if @hr <> 0 
  begin
 	  exec sp_OAGetErrorInfo @objectId, @src out, @desc out
    set @step = -1
    raiserror('Failed to create instance', 16, 1)
  end
   
  declare @site varchar(150) = 'http://www.cbar.az/currencies/' + convert(varchar, @Date, 104) + '.xml'
  exec @hr = sp_OAMethod @objectId, 'Open', null, 'Get', @site, 'False'
  if @hr <> 0 
  begin
	  exec sp_OAGetErrorInfo @objectId, @src out, @desc out
    set @step = -2
    raiserror('Failed to open the site', 16, 1)
  end

  exec @hr = sp_OAMethod @objectId, 'Send', null, @status
  if @hr <> 0 
  begin
	  exec sp_OAGetErrorInfo @objectId, @src out, @desc out
    set @step = -4
    raiserror('Failed to Send', 16, 1)
  end

  exec @hr = sp_OAGetProperty  @objectId, 'Status', @status out
  if @hr <> 0 
  begin
	  exec sp_OAGetErrorInfo @objectId, @src out, @desc out
    set @step = -5
    raiserror('Failed Status', 16, 1)
  end

  if @status <> 200
  begin
    -- raiserror('Invalid response status', 16, 1) with log
	  set @step = -6
    raiserror('Invalid response status', 16, 1)    
  end
 
  declare @httpresult as table(http nvarchar(max)) 
   insert @httpresult
     exec @hr = sp_OAGetProperty @objectId, 'responsetext'

  if @hr <> 0 
  begin
	  exec sp_OAGetErrorInfo @objectId, @src out, @desc out
    set @step = -7
    raiserror('Failed to get Responsetext', 16, 1)
  end

  declare @t as table(x xml)
  insert into @t 
  select cast(replace(http, '<?xml version="1.0" encoding="UTF-8"?>', '<?xml version="1.0" encoding="UTF-16"?>') as xml) from @httpresult

  merge into dbo.CurrencyRate as trg using
  (
   select m.c.value('@Code', 'varchar(max)') as FromCode
        , 'AZN' as ToCode
        , convert(varchar, d.x, 112) as DateKey
        , d.x as RateDate
        , m.c.value('@Code', 'varchar(max)') as id
        , m.c.query('./Value').value('.', 'decimal(12, 4)') as Rate
        , m.c.query('./Nominal').value('.', 'int') as Nominal
     from @t as s
    outer apply s.x.nodes('/ValCurs/ValType/Valute') as m(c)
    cross join @Dates as d 
    where  m.c.value('@Code', 'varchar(max)') in ('USD', 'EUR')
   ) as src on trg.RateDate = src.RateDate and trg.DateKey = src.DateKey and trg.FromCode  = src.FromCode and trg.ToCode = src.ToCode 
  when not matched by target then 
	insert(DateKey, RateDate, FromCode, ToCode, Rate, Nominal, DataSourceId, CreatedBy, ModifiedBy)
	values(src.DateKey, src.RateDate, src.FromCode, src.ToCode, Rate, Nominal, -1, @UserId, @UserId)
  when matched then 
  update set Nominal = src.Nominal
           , Rate = src.Rate
           , DateModified = getdate()
           , ModifiedBy = @UserId
  output iif($action = 'INSERT', 0, 1) into @out;

  select @isUpdated = o.isUpdated from @out o;
  --if util.GetBitConfig ('ExchangeRateDebugOn', 'Config') = 1
  insert log.GetExchangeRate(Code, Action, hResult, src, description)
  select 'AZN', iif(@isUpdated = 1, 'Update', 'Insert'), null, object_name(@@procid), 'Success'

commit transaction CurrencyAZN;

  end try
  begin catch

    if (@@trancount > 0) rollback transaction CurrencyAZN;
    insert log.GetExchangeRate(Code, Action, hResult, src, description)
    select 'AZN' Code, error_message() as Action, convert(varbinary(4), @hr) hr, @site source, @desc description
    --where @step <> 0
    --throw;

  end catch;

  exec @hr = sp_OADestroy @objectId
  if @hr <> 0 print -8

end
go

-- ====================
-- every day from daily https://nbg.gov.ge/gw/api/ct/monetarypolicy/currencies/en/json/?date=2023-07-15
-- ====================
create or alter proc cur.GetExchangeRateGEL
(
  @Date datetime2 = null
, @UserId int = -1
)
as
begin
 set nocount on;
 begin transaction CurrencyGEL
 begin try

  set @Date = isnull(@Date, getdate())
  declare @Dates as table(x date)
  insert into @Dates
  select @Date

  declare @src varchar(255), @desc varchar(255), @step int = 0; 
  declare @hr int, @objectId int, @status int, @dayOfWeek int, @isUpdated bit;
  declare @out as table(isUpdated int);

  exec @hr = sp_OACreate 'MSXML2.ServerXMLHTTP', @objectId out
  if @hr<>0 
  begin
	  exec sp_OAGetErrorInfo @objectId
	  set @step = -1
    raiserror('Failed to create instance', 16, 1)
  end

  declare @site varchar(150) = 'https://nbg.gov.ge/gw/api/ct/monetarypolicy/currencies/en/json/?date=' + convert(varchar, @Date, 23);

  exec @hr = sp_OAMethod @objectId, 'Open', null, 'Get', @site, 'False'
  if @hr<>0 
  begin
	  exec sp_OAGetErrorInfo @objectId
	  set @step = -2
    raiserror('Failed to open the site', 16, 1)
  end

  exec @hr = sp_OAMethod @objectId, 'Send', null, @status
  if @hr <> 0 
  begin
	  exec sp_OAGetErrorInfo @objectId
	  set @step = -4
    raiserror('Failed to Send', 16, 1)
  end

  exec @hr = sp_OAGetProperty  @objectId, 'Status', @status out
  if @hr <> 0 
  begin
	  exec sp_OAGetErrorInfo @objectId
	  set @step = -5
    raiserror('Failed Status', 16, 1)
  end

  if @status <> 200
  begin
    set @step = -6
    raiserror('Invalid response status', 16, 1)    
  end

  declare @httpresult as table(http nvarchar(max)) 
   insert @httpresult
     exec @hr = sp_OAGetProperty @objectId, 'responsetext'

  if @hr <> 0 
  begin
	  exec sp_OAGetErrorInfo @objectId
	  set @step = -7
    raiserror('Failed to get Responsetext', 16, 1)
  end

  merge into dbo.CurrencyRate as trg using
  (
   select Structures.code as FromCode
        , 'GEL' as ToCode
        , convert(varchar, d.x, 112) as DateKey
        , d.x as RateDate
        , Structures.rateFormated as Rate
        , Structures.quantity as Nominal
     from @httpresult as hr
    cross apply openjson (hr.http)
    with 
    (
         currencies nvarchar(max) as json
       , date datetime2 '$.date'
    )
    as Projects   
    cross apply openjson (Projects.currencies)
    with
    (
         code nvarchar(20)
       , quantity int
       , rateFormated money 
    ) as Structures
   cross join @Dates as d 
   where Structures.code in ('USD', 'EUR')  

   ) as src on trg.RateDate = src.RateDate and trg.DateKey = src.DateKey and trg.FromCode  = src.FromCode and trg.ToCode = src.ToCode 
  when not matched by target then 
	insert(DateKey, RateDate, FromCode, ToCode, Rate, Nominal, DataSourceId, CreatedBy, ModifiedBy)
	values(src.DateKey, src.RateDate, src.FromCode, src.ToCode, Rate, Nominal, -1, @UserId, @UserId)
  when matched then 
  update set Nominal = src.Nominal
           , Rate = src.Rate
           , DateModified = getdate()
           , ModifiedBy = @UserId
      output iif($action = 'INSERT', 0, 1) into @out;

  select @isUpdated = o.isUpdated from @out o;
  --if util.GetBitConfig ('ExchangeRateDebugOn', 'Config') = 1
  insert log.GetExchangeRate(Code, Action, hResult, src, description)
  select 'GEL', iif(@isUpdated = 1, 'Update', 'Insert'), null, object_name(@@procid), 'Success'
 
  
commit transaction CurrencyGEL;

  end try
  begin catch

    if (@@trancount > 0) rollback transaction CurrencyGEL;
    insert log.GetExchangeRate(Code, Action, hResult, src, description)
    select 'GEL' Code, error_message() as Action, convert(varbinary(4), @hr) hr, @site source, @desc description
  --throw;

  end catch;

  exec @hr = sp_OADestroy @objectId
  if @hr <> 0 print -8

end
go

-- ====================
-- every day from daily https://nationalbank.kz/en/exchangerates/ezhednevnye-oficialnye-rynochnye-kursy-valyut
-- ====================
create or alter proc cur.GetExchangeRateKZT
(
  @Date datetime2 = null
, @UserId int = -1
)
as
begin
 set nocount on;
 begin transaction CurrencyKZ
 begin try

--set @Date = isnull(@Date, getdate())
set @Date = getdate() -- only for current  date
declare @Dates as table(x date)
insert into @Dates
select @Date

--if(datediff(day, 0, @Date)%7 = 0/*4*/)
--begin 
--   insert into @Dates
--   values(dateadd(day, -1, @Date)), (dateadd(day, -2, @Date))
--end

  declare @src varchar(255), @desc varchar(255), @step int = 0; -- @hResult varchar(255),
  declare @hr int, @objectId int, @status int, @dayOfWeek int, @isUpdated bit;
  declare @out as table(isUpdated int);

exec @hr = sp_OACreate 'MSXML2.ServerXMLHTTP', @objectId out
if @hr<>0 
begin
	exec sp_OAGetErrorInfo @objectId
  set @step = -1
  raiserror('Failed to create instance', 16, 1)
end

declare @site varchar(150) = 'https://nationalbank.kz/en/exchangerates/ezhednevnye-oficialnye-rynochnye-kursy-valyut'
exec @hr = sp_OAMethod @objectId, 'Open', null, 'Get', @site, 'False'
if @hr<>0 
begin
	exec sp_OAGetErrorInfo @objectId
  set @step = -2
  raiserror('Failed to open the site', 16, 1)
end

exec @hr = sp_OAMethod @objectId, 'Send', null, @status
if @hr <> 0 
begin
	exec sp_OAGetErrorInfo @objectId
  set @step = -4
  raiserror('Failed to Send', 16, 1)
end

exec @hr = sp_OAGetProperty  @objectId, 'Status', @status out
if @hr <> 0 
begin
	exec sp_OAGetErrorInfo @objectId
  set @step = -5
  raiserror('Failed Status', 16, 1)
end

if @status <> 200
begin
  set @step = -6
  raiserror('Invalid response status', 16, 1)    
end
 
declare @httpresult as table(http nvarchar(max)) 
 insert @httpresult
   exec @hr = sp_OAGetProperty @objectId, 'responsetext'

if @hr <> 0 
begin
	exec sp_OAGetErrorInfo @objectId
  set @step = -7
  raiserror('Failed to get Responsetext', 16, 1)
end
--select * from @httpresult
declare @First int, @Last int, @Search varchar(max);
declare @t as table(FromCode varchar(10), ToCode varchar(10), Nominal int, Rate decimal(12, 4));

select @First = charindex('<td>USD / KZT</td>', http) from @httpresult
select @First = charindex('<td>', http, @First + 1) from @httpresult
select @Last = charindex('</td>', http, @First + 1) from @httpresult
select @Search = substring(http, @First + 4, @last - @First - 4) from @httpresult

insert into @t  
select 'USD' as FromCode
     , 'KZT' as ToCode
     , 1 as Nominal
     , convert(decimal(12, 4), @Search) as cMoney   	 

select @First = charindex('<td>EUR / KZT</td>', http) from @httpresult
select @First = charindex('<td>', http, @First + 1) from @httpresult
select @Last = charindex('</td>', http, @First + 1) from @httpresult

select @Search = substring(http, @First + 4, @last - @First - 4) from @httpresult
insert into @t  
select 'EUR' as FromCode
     , 'KZT' as ToCode
     , 1 as Nominal
     , convert(decimal(12, 4), @Search) as cMoney   

  merge into dbo.CurrencyRate as trg using
  (
   select s.FromCode
        , s.ToCode
        , convert(varchar, d.x, 112) as DateKey
        , d.x as RateDate
        , s.Rate
        , s.Nominal
     from @t as s
    cross join @Dates as d 

   ) as src on trg.RateDate = src.RateDate and trg.DateKey = src.DateKey and trg.FromCode  = src.FromCode and trg.ToCode = src.ToCode 
  when not matched by target then 
	insert(DateKey, RateDate, FromCode, ToCode, Rate, Nominal, DataSourceId, CreatedBy, ModifiedBy)
	values(src.DateKey, src.RateDate, src.FromCode, src.ToCode, Rate, Nominal, -1, @UserId, @UserId)
  when matched then 
  update set Nominal = src.Nominal
           , Rate = src.Rate
           , DateModified = getdate()
           , ModifiedBy = @UserId
      output iif($action = 'INSERT', 0, 1) into @out;

  select @isUpdated = o.isUpdated from @out o;
  --if util.GetBitConfig ('ExchangeRateDebugOn', 'Config') = 1
  insert log.GetExchangeRate(Code, Action, hResult, src, description)
  select 'KZ', iif(@isUpdated = 1, 'Update', 'Insert'), null, object_name(@@procid), 'Success'

 commit transaction CurrencyKZ;

 end try
 begin catch

   if (@@trancount > 0) rollback transaction CurrencyKZ;
   insert log.GetExchangeRate(Code, Action, hResult, src, description)
   select 'KZ' Code, error_message() as Action, convert(varbinary(4), @hr) hr, @site source, @desc description
 --throw;

 end catch;

 exec @hr = sp_OADestroy @objectId
 if @hr <> 0 print -8

end
go