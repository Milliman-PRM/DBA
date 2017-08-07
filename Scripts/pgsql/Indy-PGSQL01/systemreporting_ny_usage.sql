select 	usr.username,
		split_part(document, '\', 3) as ReportName,
        substring(message from '(\w*\.csv)') as FileName,
		count(qvauditlog.id),
		useraccessdatetime >= date_trunc('month', current_date - interval '1' month) as StartDate,
		and useraccessdatetime < date_trunc('month', current_date) as EndDate

from qvauditlog
		inner join "user" as usr on qvauditlog.fk_user_id = usr.id

where document like '0000EXT01\\NEWYORK\\%'
		and useraccessdatetime >= date_trunc('month', current_date - interval '1' month)
  		and useraccessdatetime < date_trunc('month', current_date)
        and message like 'action(11)%'

group by usr.username, message, document

order by username, reportname, filename;
