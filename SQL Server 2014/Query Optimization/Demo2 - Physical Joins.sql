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

-- Drop all indexes first
Use AdventureWorks2012
Go

SET STATISTICS IO, TIME ON--, PROFILE ON;
GO

/***********************************************************************
 NEVER RUN THE BELOW TWO COMMANDS IN PRODUCTION
 UNLESS YOU HAVE A REASON TO. THIS WILL ESSENTIALLY
 ELIMINATE THE BUFFER CACHE AND PLAN CACHE THAT SQL SERVER HAS BUILT UP
 ***********************************************************************/

DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO

-- 
Select Name, SafetyStockLevel, ListPrice, ActualCost, Quantity 
From TestTransactionHistory TPH
Inner Join TestProduct TP
On TP.ProductID = TPH.ProductID
Where Name like 'Bearing%'
Go

Select Count(*) From TestTransactionHistory
Select Count(*) From TestProduct
Go

/***********************************************************************
 NEVER RUN THE BELOW TWO COMMANDS IN PRODUCTION
 UNLESS YOU HAVE A REASON TO. THIS WILL ESSENTIALLY
 ELIMINATE THE BUFFER CACHE AND PLAN CACHE THAT SQL SERVER HAS BUILT UP
 ***********************************************************************/
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO

-- What happens if I Force the order?
Select Name, SafetyStockLevel, ListPrice, ActualCost, Quantity 
From TestTransactionHistory TPH
Inner Join TestProduct TP
On TP.ProductID = TPH.ProductID
Where Name like 'Bearing%'
Option (FORCE ORDER) --Rerun with ForceOrder
Go

--Add Index on TestTransactionHistory for Join Clause. What does this do for us?
USE [AdventureWorks2012]
GO

CREATE CLUSTERED INDEX [CI_TestTransactionHistory_ProductID_TransactionID] ON [dbo].[TestTransactionHistory]
(
	[TransactionID] ASC,
	[ProductID] ASC
)

/***********************************************************************
 NEVER RUN THE BELOW TWO COMMANDS IN PRODUCTION
 UNLESS YOU HAVE A REASON TO. THIS WILL ESSENTIALLY
 ELIMINATE THE BUFFER CACHE AND PLAN CACHE THAT SQL SERVER HAS BUILT UP
 ***********************************************************************/
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO

-- Is there anything wrong?
Select Name, SafetyStockLevel, ListPrice, ActualCost, Quantity 
From TestTransactionHistory TPH
Inner Join TestProduct TP
On TP.ProductID = TPH.ProductID
Where Name = 'Bearing Ball'
Go

-- Let's re-order the index
DROP INDEX [CI_TestTransactionHistory_ProductID_TransactionID] ON [dbo].[TestTransactionHistory] 
GO
CREATE CLUSTERED INDEX [CI_TestTransactionHistory_ProductID_TransactionID] ON [dbo].[TestTransactionHistory]
(
	[ProductID] ASC,
	[TransactionID] ASC
	
)
GO

--Ahhh a seek now
Select Name, SafetyStockLevel, ListPrice, ActualCost, Quantity 
From TestTransactionHistory TPH
Inner Join TestProduct TP
On TP.ProductID = TPH.ProductID
Where Name = 'Bearing Ball'
Go

/*MERGE JOIN DEMO*/

--Let's see what we get with no indexes

SELECT * FROM TestWorkOrder INNER JOIN TestWorkOrderRouting 
ON TestWorkOrder.WorkOrderID = TestWorkOrderRouting.WorkOrderID 
WHERE TestWorkOrderRouting.ModifiedDate >  CAST('2005-08-01' AS DATETIME)
GO

--Adding a PK to the TestWorkOrder Table

/****** Object:  Index [PK_TestWorkOrder]    Script Date: 9/5/2012 2:58:19 PM ******/
ALTER TABLE [dbo].[TestWorkOrder] ADD  CONSTRAINT [PK_TestWorkOrder] PRIMARY KEY CLUSTERED 
(
	[WorkOrderID] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO


--Did It help? Not much
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO

SELECT * FROM TestWorkOrder INNER JOIN TestWorkOrderRouting 
ON TestWorkOrder.WorkOrderID = TestWorkOrderRouting.WorkOrderID 
WHERE TestWorkOrderRouting.ModifiedDate >  CAST('2005-08-01' AS DATETIME)
GO

--Lets add another index to the TestWorkOrderRouting
/****** Object:  Index [PK_TestWorkOrderRouting]    Script Date: 9/5/2012 2:58:07 PM ******/
ALTER TABLE [dbo].[TestWorkOrderRouting] ADD  CONSTRAINT [PK_TestWorkOrderRouting] PRIMARY KEY CLUSTERED 
(
	[WorkOrderID] ASC,
	[ProductID] ASC,
	[OperationSequence] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, SORT_IN_TEMPDB = OFF, IGNORE_DUP_KEY = OFF, ONLINE = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
GO

/***********************************************************************
 NEVER RUN THE BELOW TWO COMMANDS IN PRODUCTION
 UNLESS YOU HAVE A REASON TO. THIS WILL ESSENTIALLY
 ELIMINATE THE BUFFER CACHE AND PLAN CACHE THAT SQL SERVER HAS BUILT UP
 ***********************************************************************/
--Did It help now?
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO

SELECT * FROM TestWorkOrder INNER JOIN TestWorkOrderRouting 
ON TestWorkOrder.WorkOrderID = TestWorkOrderRouting.WorkOrderID 
WHERE TestWorkOrderRouting.ModifiedDate >  CAST('2005-08-01' AS DATETIME)
GO


