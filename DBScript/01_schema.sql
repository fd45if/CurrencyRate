use master
go

if DB_ID (N'CurrencyRate') is null
create database CurrencyRate collate Cyrillic_General_CI_AS ;
go

use CurrencyRate
go

if not exists (select 1 from sys.schemas where name = 'cur')
exec('create schema cur authorization dbo');
go

if not exists (select 1 from sys.schemas where name = 'log')
exec('create schema log authorization dbo');
go

-- ===================================
if object_id('dbo.Currency') is null  
create table dbo.Currency
(
    Code nchar(3) not null constraint PK_dbo_Currency primary key
  , Name nvarchar(50) not null
  , Symbol nvarchar(10)
  , CurrencyDesc nvarchar(50) null

  , isDeleted bit not null constraint DF_dbo_Currency_isDeleted default 0 
  , DateCreated datetime2(7) not null constraint DF_dbo_Currency_DateCreated default getdate() 
  , DateModified datetime2(7) not null constraint DF_dbo_Currency_DateModified default getdate()
  , CreatedBy int not null constraint DF_dbo_Currency_CreatedBy default(-1) 
  , ModifiedBy int not null constraint DF_dbo_Currency_ModifiedBy default(-1) 
  
  , ExternalId varchar(255) null
  , DataSourceId int null
);
go  

-- ===================================
if object_id('dbo.CurrencyRate') is null  
create table dbo.CurrencyRate
(
    Id int identity(1,1) not null constraint PK_dbo_CurrencyRate primary key
  , DateKey int not null
  , RateDate date
  , FromCode nchar(3) not null constraint FK_dbo_CurrencyRate_From_to_Currency_Code foreign key references dbo.Currency(Code)
  , ToCode nchar(3) not null constraint FK_dbo_CurrencyRate_To_to_Currency_Code foreign key references dbo.Currency(Code)
  , Rate decimal(10, 4) not null
  , Nominal int not null

  , isDeleted bit not null constraint DF_dbo_CurrencyRate_isDeleted default 0 
  , DateCreated datetime2(7) not null constraint DF_dbo_CurrencyRate_DateCreated default getdate() 
  , DateModified datetime2(7) not null constraint DF_dbo_CurrencyRate_DateModified default getdate()
  , CreatedBy int not null constraint DF_dbo_CurrencyRate_CreatedBy default(-1) 
  , ModifiedBy int not null constraint DF_dbo_CurrencyRate_ModifiedBy default(-1) 
  
  , ExternalId varchar(255) null
  , DataSourceId int null
);
go  

if object_id('log.GetExchangeRate') is null  
create table log.GetExchangeRate
(
    Id int identity(1,1) not null constraint PK_log_GetExchangeRate primary key
  , Code varchar(10) null
  , Action varchar(255) null
  , hResult varbinary(4) null
  , src varchar(255) null
  , Description varchar(255) null
	
  , DateCreated datetime2(7) not null constraint DF_log_GetExchangeRate_DateCreated default getdate() 
  , DateModified datetime2(7) not null constraint DF_log_GetExchangeRate_DateModified default getdate()
  , CreatedBy int not null constraint DF_log_GetExchangeRate_CreatedBy default(-1)
  , ModifiedBy int not null constraint DF_log_GetExchangeRate_ModifiedBy default(-1) 
  , isDeleted bit not null constraint DF_log_GetExchangeRate_isDeleted default 0 
	
  , ExternalId varchar(255) null
  , DataSourceId int null
) 
go

if not exists (select 1 from sys.objects where name = 'UQ_dbo_CurrencyRate_DateKey_FromCode_ToCode')
alter table dbo.CurrencyRate add constraint UQ_dbo_CurrencyRate_DateKey_FromCode_ToCode unique nonclustered (DateKey, FromCode, ToCode)
go
-- ======================================================================
if object_id('dbo.Country') is null  
create table dbo.Country
(
    Id int identity(1,1) not null constraint PK_dbo_Country_Id primary key
  , Code varchar(2) not null 
  , Name varchar(100) not null constraint UQ_dbo_Country_Name unique
  , CurrencyCode nchar(3) not null constraint FK_dbo_Country_CurrencyCode_to_Currency_Code foreign key references dbo.Currency (Code)
  , Vat decimal(19, 2) null

  , DateCreated datetime2(7) not null constraint DF_dbo_Country_DateCreated default getdate() 
  , DateModified datetime2(7) not null constraint DF_dbo_Country_DateModified default getdate()
  , CreatedBy int not null constraint DF_dbo_Country_CreatedBy default(-1)
  , ModifiedBy int not null constraint DF_dbo_Country_ModifiedBy default(-1) 
  , isDeleted bit not null constraint DF_dbo_Country_isDeleted default 0 
	
  , ExternalId varchar(255) null
  , DataSourceId int null
) 
go




