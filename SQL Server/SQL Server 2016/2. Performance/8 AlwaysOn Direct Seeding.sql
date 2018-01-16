-- ====================================
-- Step 1) Setup AG on primary
-- ====================================
Use Master
go

CREATE AVAILABILITY GROUP [PankajTSP-AGDS01]   
FOR DATABASE TradingSystem   
REPLICA ON N'PankajTSP-SQL01' WITH (ENDPOINT_URL = N'TCP://PankajTSP-SQL01.pankajtsp.com:5022',  
    FAILOVER_MODE = AUTOMATIC,  
    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,   
    BACKUP_PRIORITY = 50,   
    SECONDARY_ROLE(ALLOW_CONNECTIONS = NO),   
    SEEDING_MODE = AUTOMATIC),   
N'PankajTSP-SQL02' WITH (ENDPOINT_URL = N'TCP://PankajTSP-SQL02.pankajtsp.com:5022',   
    FAILOVER_MODE = AUTOMATIC,   
    AVAILABILITY_MODE = SYNCHRONOUS_COMMIT,   
    BACKUP_PRIORITY = 50,   
    SECONDARY_ROLE(ALLOW_CONNECTIONS = NO),   
    SEEDING_MODE = AUTOMATIC);   
GO 

-- ===============================================
-- Step 2) connect to secondary(s) and join the AG
-- ===============================================
use master
go

ALTER AVAILABILITY GROUP [PankajTSP-AGDS01] JOIN 
ALTER AVAILABILITY GROUP [PankajTSP-AGDS01] GRANT CREATE ANY DATABASE
GO 

-- ===============================================
-- Step 3) Cleanup
-- ===============================================
--Primary
USE [master]
GO

ALTER AVAILABILITY GROUP [PankajTSP-AGDS01]
REMOVE REPLICA ON N'PankajTSP-SQL02';
GO
ALTER AVAILABILITY GROUP [PankajTSP-AGDS01] REMOVE DATABASE TradingSystem;
GO
DROP AVAILABILITY GROUP [PankajTSP-AGDS01];
GO

--Secondary
DROP DATABASE TradingSystem
