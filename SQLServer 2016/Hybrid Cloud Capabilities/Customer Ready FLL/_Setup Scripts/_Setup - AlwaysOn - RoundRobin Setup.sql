-- =====================================================================================================
-- Documentation: https://msdn.microsoft.com/en-us/library/bb510411.aspx#columnstore
-- =====================================================================================================
/*
Key Points:
-- TIP: Run Ostress first then explain

1) Updateable NCCI after upgrade for operational analytics
2) CCI can have secondary B-Tree Indexes
3) String(Filter on string) and aggregate (ex count(*) group by) predicate pushdown
4) Reorg eliminates fragmentation caused by deletes
5) Batch mode supported with non-parallel plan
6) Support for constraints
*/


ALTER AVAILABILITY GROUP [PankajTSP-AG01]
 MODIFY REPLICA ON
N'PankajTSP-SQL01' WITH 
(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
ALTER AVAILABILITY GROUP [PankajTSP-AG01]
 MODIFY REPLICA ON
N'PankajTSP-SQL01' WITH 
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://PankajTSP-SQL01.pankajtsp.com:1433'));

ALTER AVAILABILITY GROUP [PankajTSP-AG01]
 MODIFY REPLICA ON
N'PankajTSP-SQL02' WITH 
(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
ALTER AVAILABILITY GROUP [PankajTSP-AG01]
 MODIFY REPLICA ON
N'PankajTSP-SQL02' WITH 
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://PankajTSP-SQL02.pankajtsp.com:1433'));

ALTER AVAILABILITY GROUP [PankajTSP-AG01]
 MODIFY REPLICA ON
N'PankajTSP-SQL03' WITH 
(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
ALTER AVAILABILITY GROUP [PankajTSP-AG01]
 MODIFY REPLICA ON
N'PankajTSP-SQL03' WITH 
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://PankajTSP-SQL03.pankajtsp.com:1433'));

ALTER AVAILABILITY GROUP [PankajTSP-AG01] 
MODIFY REPLICA ON
N'PankajTSP-SQL01' WITH 
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=(('PankajTSP-SQL02','PankajTSP-SQL03'),'PankajTSP-SQL01')));

ALTER AVAILABILITY GROUP [PankajTSP-AG01] 
MODIFY REPLICA ON
N'PankajTSP-SQL02' WITH 
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=(('PankajTSP-SQL01','PankajTSP-SQL03'),'PankajTSP-SQL02')));
GO

ALTER AVAILABILITY GROUP [PankajTSP-AG01] 
MODIFY REPLICA ON
N'PankajTSP-SQL03' WITH 
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=(('PankajTSP-SQL01','PankajTSP-SQL02'),'PankajTSP-SQL03')));
GO
