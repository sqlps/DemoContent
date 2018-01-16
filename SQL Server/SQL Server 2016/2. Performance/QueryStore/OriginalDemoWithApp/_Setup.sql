-- Query Store Hands-on Lab
-- 1.1 Create demo database and turn on Query Store
USE MASTER
GO

IF EXISTS (SELECT * FROM sys.databases WHERE name = 'QueryStoreDemo')
BEGIN
	ALTER DATABASE [QueryStoreDemo] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP DATABASE QueryStoreDemo
END
GO
USE [master]
GO

/****** Object:  Database [QueryStoreDemo]    Script Date: 10/6/2015 2:11:52 AM ******/
CREATE DATABASE [QueryStoreDemo]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'QueryStoreDEmo', FILENAME = N'D:\Data\QueryStoreDEmo.mdf' , SIZE = 4096KB , MAXSIZE = UNLIMITED, FILEGROWTH = 1024KB )
 LOG ON 
( NAME = N'QueryStoreDEmo_log', FILENAME = N'D:\Data\QueryStoreDEmo_log.ldf' , SIZE = 1024KB , MAXSIZE = 2048GB , FILEGROWTH = 10%)
GO

USE QueryStoreDemo
GO
ALTER DATABASE CURRENT SET QUERY_STORE (INTERVAL_LENGTH_MINUTES = 1)
ALTER DATABASE CURRENT SET QUERY_STORE = ON
GO

CREATE TABLE t1(c1 int, c2 int, c3 binary(2000))
GO

DECLARE @i int = 1
WHILE @i < 10000
BEGIN
	INSERT INTO t1(c1, c2, c3) VALUES (@i, @i, convert(varbinary(2000), @i * @i))
	SET @i = @i + 1
END
GO

INSERT INTO t1(c1, c2) VALUES (1, 1)
GO 100000

CREATE NONCLUSTERED INDEX i1 on t1 (c1)
GO
CREATE NONCLUSTERED INDEX i2 on t1 (c2)
GO

CREATE PROCEDURE sp_dummyworkload 
	@p1 int,
	@p2 int
AS
BEGIN
	SELECT TOP 10000 * FROM t1 WHERE  c1=@p1 and c2=@p2	
END
GO

ALTER DATABASE QueryStoreDemo SET QUERY_STORE CLEAR
GO  -- end of database create script
