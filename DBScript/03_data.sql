use CurrencyRate
go

merge into dbo.Currency as trg using
(
  values ((N'EUR'), (N'Euro'), (N'€'), (N''))
       , ((N'USD'), (N'Dollar'), (N'$'), (N''))
       , ((N'AZN'), (N'Manat'), (N'₼'), (N''))
       , ((N'AMD'), (N'Dram'), (N'֏'), (N''))
       , ((N'KZT'), (N'Tenge'), (N'₸'), (N''))
       
) as src(Code, Name, Symbol, CurrencyDesc) on trg.Code = src.Code  
  when not matched by target then 
	insert(Code, Name, Symbol, CurrencyDesc, DataSourceId )
	values( src.Code, src.Name, src.Symbol, src.CurrencyDesc, 1);
go 


merge into dbo.Country as trg using
(
  values (('KZ'), ('Kazakhstan'), (N'KZT'), 12)
       , (('AZ'), ('Azerbaijan'), (N'AZN'), 18)
       , (('AM'), ('Armenia'), (N'AMD'), 20)
       
) as src(Code, Name, CurrencyCode, Vat) 
  on trg.Code = src.Code  
  when not matched by target then 
	insert(Code, Name, CurrencyCode, Vat, DataSourceId )
	values( src.Code, src.Name, src.CurrencyCode, src.Vat, 1);
go