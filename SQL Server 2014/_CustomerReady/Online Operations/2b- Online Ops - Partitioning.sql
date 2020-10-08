/* This Sample Code is provided for the purpose of illustration only and is not intended 
to be used in a production environment.  THIS SAMPLE CODE AND ANY RELATED INFORMATION ARE 
PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER EXPRESSED OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE IMPLIED WARRANTIES OF MERCHANTABILITY AND/OR FITNESS FOR A PARTICULAR 
PURPOSE.  We grant You a nonexclusive, royalty-free right to use and modify the Sample Code
and to reproduce and distribute the object code form of the Sample Code, provided that You 
agree: (i) to not use Our name, logo, or trademarks to market Your software product in which
the Sample Code is embedded; (ii) to include a valid copyright notice on Your software product
in which the Sample Code is embedded; and (iii) to indemnify, hold harmless, and defend Us and
Our suppliers from and against any claims or lawsuits, including attorneys’ fees, that arise or 
result from the use or distribution of the Sample Code.
*/

-- Helper file to demo Online Ops - Lock Priority
-- Start a blocking transaction in partition 1 before switching partition
USE AdventureWorks
GO

BEGIN TRAN
INSERT INTO [Production].[TransactionHistory]      
VALUES (999999,780,53379,0,	'2012-01-01 00:00:00.000', 'W',	2,0.00,'2012-01-01 00:00:00.000')
--
--ROLLBACK TRAN 
--COMMIT TRAN
go

USE master
GO

-- This script will run forever because we don't commit or rollback transaction