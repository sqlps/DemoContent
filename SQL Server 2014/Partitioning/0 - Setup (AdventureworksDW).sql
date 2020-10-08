-- ===================================
-- This demo shows how to migrate existing 
-- ===================================

-- ===================================
-- Step 1) Create Filegroups
-- ===================================

USE [master]
GO
ALTER DATABASE [Adventureworks2008DW] ADD FILEGROUP [2002]
ALTER DATABASE [Adventureworks2008DW] ADD FILEGROUP [2003]
ALTER DATABASE [Adventureworks2008DW] ADD FILEGROUP [2004]
GO

-- ===================================
-- Step 2) Add Files
-- ===================================

USE [master]
GO
ALTER DATABASE [Adventureworks2008DW] 
ADD FILE ( NAME = N'Adventureworks2008DW_2002', 
FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Adventureworks2008DW_2002.ndf' , SIZE = 5120000KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [2002]
GO
ALTER DATABASE [Adventureworks2008DW] 
ADD FILE ( NAME = N'Adventureworks2008DW_2003', 
FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Adventureworks2008DW_2003.ndf' , SIZE = 5120000KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [2003]
GO
ALTER DATABASE [Adventureworks2008DW] 
ADD FILE ( NAME = N'Adventureworks2008DW_2004', 
FILENAME = N'C:\Program Files\Microsoft SQL Server\MSSQL13.MSSQLSERVER\MSSQL\DATA\Adventureworks2008DW_2004.ndf' , SIZE = 5120000KB , FILEGROWTH = 1024KB ) 
TO FILEGROUP [2004]
GO

-- ===================================
-- Step 3) Create Partition Function
-- ===================================

USE [Adventureworks2008DW]
GO

CREATE PARTITION FUNCTION [ByOrderDateMonthPF](int)
AS RANGE RIGHT FOR VALUES 
	(20020601, 20020701, 20020801, 20020901, 20021001, 20021101, 20021201, 
	20030101, 20030201, 20030301, 20030401, 20030501, 20030601, 20030701, 20030801, 20030901, 20031001, 20031101, 20031201, 
	20040101, 20040201, 20040301, 20040401, 20040501, 20040601, 20040701, 20040801, 20040901, 20041001, 20041101, 20041201)
GO

CREATE PARTITION FUNCTION [ByOrderDateMonthPF](int)
AS RANGE RIGHT FOR VALUES 
	(20020701, 20020801, 20020901, 20021001, 20021101, 20021201, 
	20030101, 20030201, 20030301, 20030401, 20030501, 20030601, 20030701, 20030801, 20030901, 20031001, 20031101, 20031201, 
	20040101, 20040201, 20040301, 20040401, 20040501, 20040601, 20040701, 20040801, 20040901, 20041001, 20041101, 20041201)
GO


-- ===================================
-- Step 4) Create Partition Scheme
-- ===================================
USE [Adventureworks2008DW]
GO

CREATE PARTITION SCHEME [ByOrderDateMonthRange] AS PARTITION [ByOrderDateMonthPF] 
TO ( [2002], [2002], [2002], [2002], [2002], [2002], [2002], 
	[2003], [2003], [2003], [2003], [2003], [2003], [2003], [2003], [2003], [2003], [2003], [2003], 
	[2004], [2004], [2004], [2004], [2004], [2004], [2004], [2004], [2004], [2004], [2004], [2004])
GO
-- Could have also used "ALL TO ([PRIMARY]) "

-- ==================================================
-- Step 5) Recreate Index to move table to Partition
-- ==================================================
USE [Adventureworks2008DW]
GO

CREATE CLUSTERED INDEX [FactResellerSalesPart_OrderDateKey_CI] ON [dbo].[FactResellerSales]
(
	[OrderDateKey] ASC
)WITH (DROP_EXISTING = ON)
ON [ByOrderDateMonthRange](OrderDateKey)
GO

-- ==================================================
-- Step 6) BCP in the data
-- ==================================================

--Layout of Data in various Partitions
SELECT
tbl.name AS [TableName],
scm.name AS [SchemaName],
ds.name AS [PartitinSchemeName],
pf.name AS [PartitionFunctionName],
c.name AS [PartitionColumnName],
p.partition_number AS [PartitionNumber],
prv.value AS [RightBoundaryValue],
CAST(p.rows AS float) AS [RowCount],
fg.name AS [FileGroupName],
CAST(pf.boundary_value_on_right AS int) AS [RangeType],
p.data_compression AS [DataCompression],
p.data_compression_desc AS [DataCompressionDesc]
FROM
sys.tables AS tbl
INNER JOIN sys.schemas as scm  ON tbl.schema_id=scm.schema_id
INNER JOIN sys.indexes AS idx ON idx.object_id = tbl.object_id and idx.index_id < 2
INNER JOIN sys.partitions AS p ON p.object_id=CAST(tbl.object_id AS int) AND p.index_id=idx.index_id
INNER JOIN sys.indexes AS indx ON p.object_id = indx.object_id and p.index_id = indx.index_id
INNER JOIN sys.index_columns ic ON (ic.partition_ordinal > 0) AND (ic.index_id=idx.index_id AND ic.object_id=CAST(tbl.object_id AS int))
INNER JOIN sys.columns c ON c.object_id = ic.object_id and c.column_id = ic.column_id
LEFT OUTER JOIN sys.destination_data_spaces AS dds ON dds.partition_scheme_id = indx.data_space_id and dds.destination_id = p.partition_number
LEFT OUTER JOIN sys.data_spaces AS ds ON ds.data_space_id=dds.partition_scheme_id
LEFT OUTER JOIN sys.partition_schemes AS ps ON ps.data_space_id = indx.data_space_id
LEFT OUTER JOIN sys.partition_range_values AS prv ON prv.boundary_id = p.partition_number and prv.function_id = ps.function_id
LEFT OUTER JOIN sys.filegroups AS fg ON  fg.data_space_id = dds.data_space_id or fg.data_space_id = indx.data_space_id
LEFT OUTER JOIN sys.partition_functions AS pf ON  pf.function_id = prv.function_id
WHERE EXISTS
      (SELECT DISTINCT OBJECT_NAME([object_id])
      FROM sys.partitions AS ps
      WHERE tbl.name=OBJECT_NAME([object_id])
      AND   partition_number > 1
      AND     OBJECTPROPERTY([object_id],'IsTable') = 1
      )
ORDER BY TableName,PartitionNumber

-- ==================================================
-- Step 7) Backup with compression and striping
-- ==================================================
--Create Credential using SAS (Required to stripe across URLs)

CREATE Credential [https://pankajtsp.blob.core.windows.net/sqlbackups] 
WITH IDENTITY = 'SHARED ACCESS SIGNATURE',
SECRET = 'sv=2014-02-14&sr=c&sig=JZUBTZVquYydWqoOLvu81T7SlcmyaTt1AKNxUzTpNAQ%3D&st=2016-05-25T04%3A00%3A00Z&se=2026-06-02T04%3A00%3A00Z&sp=rwdl'
GO

Backup Database Adventureworks2008DW TO
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_1.bak', 
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_2.bak',
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_3.bak',
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_4.bak'
with INIT, compression, FORMAT
-- Throughput with 2 files: BACKUP DATABASE successfully processed 470437 pages in 59.523 seconds (61.745 MB/sec).
-- Throughput with 4 files: BACKUP DATABASE successfully processed 470434 pages in 23.668 seconds (155.283 MB/sec).

-- =====================================================================
-- Step 8) Enable CSI and recreated existing index as partition aligned
--
-- You will need to drop exist Clustered index. 
-- Other indexes need to also be partition aligned. 
--
-- =====================================================================
USE [Adventureworks2008DW]
GO

DROP INDEX [FactResellerSalesPart_OrderDateKey_CI] ON [dbo].[FactResellerSales] WITH ( ONLINE = OFF )
GO
DROP INDEX [nci_FactResellerSales] ON [dbo].[FactResellerSales]
GO

CREATE CLUSTERED COLUMNSTORE INDEX [CCI_FactResellerSales] ON [dbo].[FactResellerSales] 
WITH (DROP_EXISTING = OFF, COMPRESSION_DELAY = 0)
ON [ByOrderDateMonthRange](OrderDateKey)
GO

CREATE NONCLUSTERED INDEX [nci_FactResellerSales] ON [dbo].[FactResellerSales]
(
	[ProductKey] ASC,
	[OrderDateKey] ASC,
	[DueDateKey] ASC,
	[ShipDateKey] ASC,
	[EmployeeKey] ASC,
	[PromotionKey] ASC,
	[SalesOrderNumber] ASC,
	[OrderQuantity] ASC,
	[CustomerPONumber] ASC
)
INCLUDE ( 	[CurrencyKey],
	[RevisionNumber],
	[TotalProductCost],
	[SalesAmount],
	[TaxAmt]) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, DROP_EXISTING = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) 
ON [ByOrderDateMonthRange](OrderDateKey)
GO
sp_spaceused 'FactResellerSales'
GO
-- name					rows	reserved	data		index_size	unused
-- FactResellerSales	6319850 1096384 KB	171952 KB	916944 KB	7488 KB

--Enable extra compression on years prior to 2004
ALTER TABLE [FactResellerSales] 
REBUILD PARTITION = ALL WITH (DATA_COMPRESSION =  COLUMNSTORE_ARCHIVE ON PARTITIONS (1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19)) ;
GO
sp_spaceused 'FactResellerSales'
GO
-- name					rows	reserved	data		index_size	unused
--FactResellerSales		6319850 1024896 KB	100848 KB	916944 KB	7104 KB
-- =============================================================
-- Step 9) Flip archival partitions to read only
-- =============================================================
Use master
Go
ALTER DATABASE [Adventureworks2008DW] SET SINGLE_USER WITH ROLLBACK IMMEDIATE
GO
ALTER DATABASE [Adventureworks2008DW] MODIFY FILEGROUP [2002] READ_ONLY
GO
ALTER DATABASE [Adventureworks2008DW] MODIFY FILEGROUP [2003] READ_ONLY
GO
ALTER DATABASE [Adventureworks2008DW] SET MULTI_USER WITH ROLLBACK IMMEDIATE
GO

-- =============================================================
-- Step 10) Change backup strategy to filegroup backups. Need to 
-- be using FULL recovery
-- =============================================================
--One time backups of ReadOnly FileGroups
Backup Database Adventureworks2008DW FILEGROUP = N'2002' TO
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_2002.bak' 
with INIT, compression, FORMAT
--BACKUP DATABASE...FILE=<name> successfully processed 32545 pages in 3.822 seconds (66.524 MB/sec).
Backup Database Adventureworks2008DW FILEGROUP = N'2003' TO
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_2003.bak'
with INIT, compression, FORMAT
--BACKUP DATABASE...FILE=<name> successfully processed 63737 pages in 8.047 seconds (61.879 MB/sec).

--Transition regular backups to primary FG and R/W FG
Backup Database Adventureworks2008DW FILEGROUP = N'2004', FILEGROUP = N'PRIMARY'  TO
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_2004_1.bak',
URL = N'https://pankajtsp.blob.core.windows.net/sqlbackups/AdventureworksDW2008_2004_2.bak'  
with INIT, compression, FORMAT
--BACKUP DATABASE...FILE=<name> successfully processed 43938 pages in 2.484 seconds (138.187 MB/sec).





