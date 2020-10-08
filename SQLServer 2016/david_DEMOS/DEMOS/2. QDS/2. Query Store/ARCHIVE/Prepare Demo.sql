use master;
go
if exists (select * from sys.databases where name = 'QueryStoreDemo')
begin
	ALTER DATABASE [QueryStoreDemo] SET  SINGLE_USER WITH ROLLBACK IMMEDIATE;
	DROP database QueryStoreDemo;
end

go

USE [master]
GO

/****** Object:  Database [QueryStoreDemo]    Script Date: 6/11/2015 2:46:58 PM ******/
CREATE DATABASE [QueryStoreDemo]
 CONTAINMENT = NONE
 ON  PRIMARY 
( NAME = N'QueryStoreDemo', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL20162\MSSQL\DATA\QueryStoreDemo.mdf' , SIZE = 301312KB , MAXSIZE = UNLIMITED, FILEGROWTH = 102400KB )
 LOG ON 
( NAME = N'QueryStoreDemo_log', FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.SQL20162\MSSQL\DATA\QueryStoreDemo_log.ldf' , SIZE = 1088KB , MAXSIZE = 2048GB , FILEGROWTH = 51200KB )
GO

ALTER DATABASE [QueryStoreDemo] SET COMPATIBILITY_LEVEL = 130
GO

IF (1 = FULLTEXTSERVICEPROPERTY('IsFullTextInstalled'))
begin
EXEC [QueryStoreDemo].[dbo].[sp_fulltext_database] @action = 'enable'
end
GO

ALTER DATABASE [QueryStoreDemo] SET ANSI_NULL_DEFAULT OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET ANSI_NULLS OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET ANSI_PADDING OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET ANSI_WARNINGS OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET ARITHABORT OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET AUTO_CLOSE OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET AUTO_SHRINK OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET AUTO_UPDATE_STATISTICS ON 
GO

ALTER DATABASE [QueryStoreDemo] SET CURSOR_CLOSE_ON_COMMIT OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET CURSOR_DEFAULT  GLOBAL 
GO

ALTER DATABASE [QueryStoreDemo] SET CONCAT_NULL_YIELDS_NULL OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET NUMERIC_ROUNDABORT OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET QUOTED_IDENTIFIER OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET RECURSIVE_TRIGGERS OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET  ENABLE_BROKER 
GO

ALTER DATABASE [QueryStoreDemo] SET AUTO_UPDATE_STATISTICS_ASYNC OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET DATE_CORRELATION_OPTIMIZATION OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET TRUSTWORTHY OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET ALLOW_SNAPSHOT_ISOLATION OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET PARAMETERIZATION SIMPLE 
GO

ALTER DATABASE [QueryStoreDemo] SET READ_COMMITTED_SNAPSHOT OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET HONOR_BROKER_PRIORITY OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET RECOVERY BULK_LOGGED 
GO

ALTER DATABASE [QueryStoreDemo] SET  MULTI_USER 
GO

ALTER DATABASE [QueryStoreDemo] SET PAGE_VERIFY CHECKSUM  
GO

ALTER DATABASE [QueryStoreDemo] SET DB_CHAINING OFF 
GO

ALTER DATABASE [QueryStoreDemo] SET FILESTREAM( NON_TRANSACTED_ACCESS = OFF ) 
GO

ALTER DATABASE [QueryStoreDemo] SET TARGET_RECOVERY_TIME = 0 SECONDS 
GO

ALTER DATABASE [QueryStoreDemo] SET DELAYED_DURABILITY = DISABLED 
GO

ALTER DATABASE [QueryStoreDemo] SET QUERY_STORE = ON
GO

ALTER DATABASE [QueryStoreDemo] SET QUERY_STORE (OPERATION_MODE = READ_WRITE, CLEANUP_POLICY = (STALE_QUERY_THRESHOLD_DAYS = 367), DATA_FLUSH_INTERVAL_SECONDS = 900, INTERVAL_LENGTH_MINUTES = 1, MAX_STORAGE_SIZE_MB = 100, QUERY_CAPTURE_MODE = ALL, SIZE_BASED_CLEANUP_MODE = OFF)
GO

ALTER DATABASE [QueryStoreDemo] SET  READ_WRITE 
GO


use QueryStoreDemo
go
alter database current set query_store (interval_length_minutes = 1)
alter database current set query_store = ON;


go

create table t1(c1 int, c2 int, c3 binary(2000))
go

declare @i int = 1
while @i < 10000
begin
	insert into t1(c1, c2, c3) values (@i, @i, convert(varbinary(2000), @i * @i))
	set @i = @i + 1
end
go

insert into t1(c1, c2) values (1, 1)
go 100000

create nonclustered index i1 on t1 (c1)
go
create nonclustered index i2 on t1 (c2)
go



CREATE PROCEDURE sp_dummyworkload 
	@p1 int,
	@p2 int
AS
BEGIN
	select top 10000 * from t1 where  c1=@p1 and c2=@p2	
END
GO

alter database QueryStoreDemo set query_store clear;
alter database QueryStoreDemo set query_store (query_capture_mode = AUTO);

go

