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

use master
go
ALTER AVAILABILITY GROUP [SQL2014-ag]
MODIFY REPLICA ON
N'SQL2014-SQL1' WITH 
(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
ALTER AVAILABILITY GROUP [SQL2014-ag]
MODIFY REPLICA ON
N'SQL2014-SQL1' WITH 
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://SQL2014-SQL1.PankajTSP.com:2866'));
ALTER AVAILABILITY GROUP [SQL2014-ag]
MODIFY REPLICA ON
N'SQL2014-SQL2' WITH 
(SECONDARY_ROLE (ALLOW_CONNECTIONS = READ_ONLY));
ALTER AVAILABILITY GROUP [SQL2014-ag]
MODIFY REPLICA ON
N'SQL2014-SQL2' WITH 
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://SQL2014-SQL2.PankajTSP.com:2866'));
ALTER AVAILABILITY GROUP [SQL2014-ag] 
MODIFY REPLICA ON
N'SQL2014-SQL1' WITH 
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('SQL2014-SQL2','SQL2014-SQL1')));
ALTER AVAILABILITY GROUP [SQL2014-ag] 
MODIFY REPLICA ON
N'SQL2014-SQL2' WITH 
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('SQL2014-SQL1','SQL2014-SQL2')));
GO


