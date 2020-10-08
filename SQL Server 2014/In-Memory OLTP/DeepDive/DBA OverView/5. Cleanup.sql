/**********************************************
 * NOTE: DO NOT RUN IF SHOWCASING CSI AS WELL *
 **********************************************/


use master
GO

ALTER DATABASE IMOLTP_Demo 
     SET SINGLE_USER 
     WITH ROLLBACK IMMEDIATE
Go
DROP DATABASE IMOLTP_DEMO
GO

EXEC sp_configure 'show advanced options', 1
EXEC sp_configure 'max server memory (MB)', 11000
EXEC sp_configure 'min server memory (MB)', 11000
Go
Reconfigure
Go