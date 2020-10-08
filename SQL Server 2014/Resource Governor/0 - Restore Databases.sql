IF EXISTS (SELECT name FROM sys.databases WHERE name LIKE 'Customer1DB')
BEGIN
	ALTER DATABASE [Customer1DB] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [Customer1DB]
END
GO
IF EXISTS (SELECT name FROM sys.databases WHERE name LIKE 'Customer2DB')
BEGIN
	ALTER DATABASE [Customer2DB] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE
	DROP DATABASE [Customer2DB]
END
GO

USE [master]
RESTORE DATABASE [Customer1DB] FROM  DISK = N'D:\Backup\Customer1DB.bak' WITH  FILE = 1,  MOVE N'tpclineitem' TO N'D:\DATA\Customer1DB.mdf',  MOVE N'tpclineitem_log' TO N'D:\LOG\Customer1DB.ldf',  NOUNLOAD,  STATS = 5

GO

USE [master]
RESTORE DATABASE [Customer2DB] FROM  DISK = N'D:\Backup\Customer2DB.bak' WITH  FILE = 1,  MOVE N'tpclineitem' TO N'D:\DATA\Customer2DB.mdf',  MOVE N'tpclineitem_log' TO N'D:\LOG\Customer2DB.ldf',  NOUNLOAD,  STATS = 5

GO

