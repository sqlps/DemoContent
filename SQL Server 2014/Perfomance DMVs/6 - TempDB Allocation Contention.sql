--From http://sqltouch.blogspot.com/2013/03/tempdb-contention-be-on-gods-side.html
Select session_id, wait_duration_ms,   resource_description 
from    sys.dm_os_waiting_tasks
where   wait_type like 'PAGE%LATCH_%' and
resource_description like '2:%'

;WITH ctePage
AS (SELECT r.session_id, r.status, r.command, r.database_id, r.blocking_session_id, r.wait_type, avg(r.wait_time) AS [wait_time]
	, r.wait_resource, cast(right(r.wait_resource, len(r.wait_resource) - charindex(':', r.wait_resource, 3)) AS INT) AS page_id
	FROM
	sys.dm_exec_requests AS r
	INNER JOIN sys.dm_exec_sessions AS s
	ON (r.session_id = s.session_id)
	WHERE r.wait_type IS NOT NULL AND s.is_user_process = 1
	GROUP BY
	GROUPING SETS ((r.session_id, r.status, r.command, r.database_id, r.blocking_session_id, r.wait_type, r.wait_time, r.wait_resource), ())
)

SELECT session_id, status, command, database_id, blocking_session_id, wait_type, wait_time, wait_resource
, (CASE
	WHEN page_id = 1 OR page_id % 8088 = 0 THEN
		'PFS_PAGE'
	WHEN page_id = 2 OR page_id % 511232 = 0 THEN
		'GAM_PAGE'
	WHEN page_id = 3 OR (page_id - 1) % 511232 = 0 THEN
		'SGAM_PAGE'
	ELSE
		'Other page'
	END) page_type
FROM ctePage
WHERE session_id IS NOT NULL