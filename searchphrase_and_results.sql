
select * from #searchphrase
select * from #numberofresults

drop table #searchphrase
drop table #numberofresults

select *
into #searchphrase
from logs
where 
(
	(partitionkey = 'SonneNielsen.Server.WebApplication.Container' and message like '%ls@sonnenielsen.dk%' and message like '%SonneNielsen.Server.WebApplication.Controllers.CompaniesController.Search%')
) 
and datepart(year,timestamp) = 2017
and datepart(month,timestamp) = 04
order by timestamp


select * 
into #numberofresults
from logs
where 
(
	(partitionkey = 'SonneNielsen.Server.Business.Container' and message like '%UserId:1004%' and message like 'SearchCompanies found%')
) 
and datepart(year,timestamp) = 2017
and datepart(month,timestamp) = 04
order by timestamp

select s.timestamp
	,case when PATINDEX ( '%PARAMETERS: <string>%' , s.message ) = 0 then 'no searchphrase'
		else
		substring(s.message,
		PATINDEX ( '%PARAMETERS: <string>%' , s.message )+20,
		PATINDEX ( '%</string><double>%' , s.message )-(PATINDEX ( '%PARAMETERS: <string>%' , s.message )+20)
		) 
		end as searchphrase
	,case when PATINDEX ( '%SearchCompanies found %' , nextresult.message ) = 0 then 'no searchphrase'
		else
		substring(nextresult.message,
		PATINDEX ( '%SearchCompanies found %' , nextresult.message )+22,
		PATINDEX ( '%results%' , nextresult.message )-(PATINDEX ( '%SearchCompanies found %' , nextresult.message )+22)
		) 
		end as numberOfResults	
		
from #searchphrase s
	join [user] u on u.
outer apply
	(
	select top 1 message,timestamp
	from #numberofresults
	where timestamp > s.timestamp
	order by timestamp
	) nextresult
where PATINDEX ( '%PARAMETERS: <string>%' , s.message ) > 0
