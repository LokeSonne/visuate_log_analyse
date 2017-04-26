drop table #searchphrase
drop table #numberofresults

select message,timestamp,u.id as userid
	,case when PATINDEX ( '%CLIENT: Identifier=%' , message ) = 0 then 'no user'
		else
		substring(message,
		PATINDEX ( '%CLIENT: Identifier%' , message )+20,
		PATINDEX ( '%, Organization=%' , message )-(PATINDEX ( '%CLIENT: Identifier%' , message )+21)
		) 
		end as identifier
	,case when PATINDEX ( '%PARAMETERS: <string>%' , message ) = 0 then 'no searchphrase'
		else
		substring(message,
		PATINDEX ( '%PARAMETERS: <string>%' , message )+20,
		PATINDEX ( '%</string>%' , message )-(PATINDEX ( '%PARAMETERS: <string>%' , message )+20)
		) 
		end as searchphrase		
into #searchphrase
from logs
inner join [user] u on u.identifier =  
		substring(message,
		PATINDEX ( '%CLIENT: Identifier%' , message )+20,
		PATINDEX ( '%, Organization=%' , message )-(PATINDEX ( '%CLIENT: Identifier%' , message )+21)
		) 
where 
partitionkey = 'SonneNielsen.Server.WebApplication.Container' 
and message like '%SonneNielsen.Server.WebApplication.Controllers.CompaniesController.Search%'
and PATINDEX ( '%CLIENT: Identifier=%' , message ) > 0
and PATINDEX ( '%PARAMETERS: <string>%' , message ) > 0
and datepart(year,timestamp) = 2017
and datepart(month,timestamp) = 04


select message,timestamp
	,case when PATINDEX ( '%UserId[:]%' , message ) = 0 then 'no user'
		else
		substring(message,
		PATINDEX ( '%UserId[:]%' , message )+7,
		PATINDEX ( '%.%' , message )-(PATINDEX ( '%UserId[:]%' , message )+8)
		) 
		end as userid
	,case when PATINDEX ( '%SearchCompanies found %' ,message ) = 0 then 'no searchphrase'
		else
		substring(message,
		PATINDEX ( '%SearchCompanies found %' ,message )+22,
		PATINDEX ( '%results%' ,message )-(PATINDEX ( '%SearchCompanies found %' ,message )+22)
		) 
		end as numberOfResults		
into #numberofresults
from logs
where 
partitionkey = 'SonneNielsen.Server.Business.Container' 
and message like 'SearchCompanies found%'
and PATINDEX ( '%UserId[:]%' , message ) > 0
and datepart(year,timestamp) = 2017
and datepart(month,timestamp) = 04

select s.timestamp
		,s.searchphrase
		,nextresult.numberOfResults
		,s.userid	
		,u.name as username
		,u.organizationid
from #searchphrase s
	inner join [user] u on u.id = s.userid
outer apply
	(
	select top 1 message,timestamp,numberOfResults
	from #numberofresults
	where timestamp > s.timestamp and userid = cast(s.userid as int)
	order by timestamp
	) nextresult
where u.organizationid = 28
order by userid,timestamp
