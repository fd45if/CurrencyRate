use CurrencyRate
go

/*
 select * from dbo.Country
 select * from dbo.Currency
 select * from dbo.CurrencyRate
 select * from log.GetExchangeRate
*/

 exec cur.GetExchangeRateAZN
 exec cur.GetExchangeRateGEL
 exec cur.GetExchangeRateKZT

 select c.Name as Country
      , cr.RateDate
      , cr.FromCode
      , cr.ToCode
      , cr.Rate
      , cr.Nominal
   from dbo.Country c
   join dbo.Currency cur on cur.Code = c.CurrencyCode
   join dbo.CurrencyRate cr on cr.ToCode = cur.Code