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

Use AdventureWorks2012
GO
Set Statistics IO, Time On
/***********************************************************************
 NEVER RUN THE BELOW TWO COMMANDS IN PRODUCTION
 UNLESS YOU HAVE A REASON TO. THIS WILL ESSENTIALLY
 ELIMINATE THE BUFFER CACHE AND PLAN CACHE THAT SQL SERVER HAS BUILT UP
 ***********************************************************************/
DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
GO
-- Step 1 Start off with a simple query
Select ProductID, Name from TestProduct
Where Name = 'Mountain-100 Silver, 42'

-- Create Index Key on ProductID and Name
CREATE CLUSTERED INDEX [CI_TestProduct_ProductID_Name] ON [dbo].[TestProduct]
(
	[ProductID] ASC,
	[Name] ASC
)
GO

--Scan Still occurs Why?
Select  ProductID, Name from TestProduct
Where Name = 'Mountain-100 Silver, 42'
GO

--Create a NCI on Name 
CREATE NONCLUSTERED INDEX [NCI_TestProduct_Name] ON [dbo].[TestProduct]
(
	[Name] ASC
)
GO

-- Rerun and seek
Select  ProductID, Name from TestProduct
Where Name = 'Mountain-100 Silver, 42'
GO

-- What happens if I reference a column not in the key?
Select ProductID, Name, Color from TestProduct
Where Name = 'Mountain-100 Silver, 42'
GO

-- Change to include Column and re-run 
DROP INDEX [NCI_TestProduct_Name] ON [dbo].[TestProduct]
GO

CREATE NONCLUSTERED INDEX [NCI_TestProduct_Name] ON [dbo].[TestProduct]
(
	[Name] ASC
)
INCLUDE ( 	[Color]) 
GO

--Re Run with includes
Select ProductID, Name, Color from TestProduct
Where Name = 'Mountain-100 Silver, 42'
GO

--Can I use the INclude Columns for a where clause?
Select ProductID, Name, Color from TestProduct
Where  Color = 'White'

