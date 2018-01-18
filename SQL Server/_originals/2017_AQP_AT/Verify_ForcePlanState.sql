USE WideWorldImporters;
GO

-- Verify that actual state of FLGP is OFF:
SELECT 
	name, 
	desired_state_desc, 
	actual_state_desc, 
	reason_desc
FROM sys.database_automatic_tuning_options;
GO

-- 4. Find recommendation suggested by database:
SELECT 
	JSON_VALUE(state, '$.currentValue') state,
	JSON_VALUE(state, '$.reason') state_transition_reason,
	t.valid_since,
	t.last_refresh,
	t.reason,
	t.score,
	planForceDetails.query_id, 
    JSON_VALUE(details, '$.implementationDetails.script') AS script,
    planForceDetails.[new plan_id], 
	planForceDetails.[recommended plan_id]
FROM sys.dm_db_tuning_recommendations AS t
CROSS APPLY OPENJSON (Details, '$.planForceDetails')
WITH 
(  
	[query_id] int '$.queryId',
    [new plan_id] int '$.regressedPlanId',
    [recommended plan_id] int '$.recommendedPlanId'
) as planForceDetails;