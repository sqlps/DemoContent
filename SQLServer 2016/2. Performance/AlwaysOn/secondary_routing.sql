/* This Sample Code is provided for the purpose of illustration only and is not intended
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys fees, that arise or
result from the use or distribution of the Sample Code.*/

ALTER AVAILABILITY GROUP SQLADMIN11_G
 MODIFY REPLICA ON
N'SQLADMIN11CN1' WITH 
(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
ALTER AVAILABILITY GROUP SQLADMIN11_G
 MODIFY REPLICA ON
N'SQLADMIN11CN1' WITH 
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://SQLADMIN11CN1.sqladmin11.lcl:1433'));

ALTER AVAILABILITY GROUP SQLADMIN11_G
 MODIFY REPLICA ON
N'SQLADMIN11CN2' WITH 
(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
ALTER AVAILABILITY GROUP SQLADMIN11_G
 MODIFY REPLICA ON
N'SQLADMIN11CN2' WITH 
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://SQLADMIN11CN2.sqladmin11.lcl:1433'));

--WHEN SQLADMIN11CN1 IS THE OWNER, READ FROM SQLADMIN11CN2, then SQLAlwaysON_SQL3
ALTER AVAILABILITY GROUP SQLADMIN11_G 
MODIFY REPLICA ON
N'SQLADMIN11CN1' WITH 
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('SQLADMIN11CN2')));
GO

--WHEN SQLADMIN11CN2 IS THE OWNER, READ FROM SQLAlwaysON_SQL3, then SQLADMIN11CN1
ALTER AVAILABILITY GROUP SQLADMIN11_G 
MODIFY REPLICA ON
N'SQLADMIN11CN2' WITH 
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('SQLADMIN11CN1')));
GO

SELECT * FROM sys.availability_read_only_routing_lists

SELECT * from sys.availability_replicas