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

DBCC DROPCLEANBUFFERS
DBCC FREEPROCCACHE
SET STATISTICS IO ON
SET STATISTICS TIME ON
GO

Use Adventureworks2012
GO


ALTER TABLE Production.ProductDescription
ADD cs_PDescription AS CHECKSUM(Description);
GO
CREATE INDEX NCI_ProductDescription_Description ON Production.ProductDescription (cs_PDescription);
GO

/*Use the index in a SELECT query. Add a second search 
condition to catch stray cases where checksums match, 
but the values are not the same.*/


SELECT * 
FROM Production.ProductDescription
WHERE Description = N'A true multi-sport bike that offers streamlined riding and a revolutionary design. Aerodynamic design lets you ride with the pros, and the gearing will conquer hilly roads.';
GO


SELECT * 
FROM Production.ProductDescription
WHERE CHECKSUM(N'A true multi-sport bike that offers streamlined riding and a revolutionary design. Aerodynamic design lets you ride with the pros, and the gearing will conquer hilly roads.') = cs_PDescription
AND Description = N'A true multi-sport bike that offers streamlined riding and a revolutionary design. Aerodynamic design lets you ride with the pros, and the gearing will conquer hilly roads.';
GO

Drop Index NCI_ProductDescription_Description ON Production.ProductDescription
GO


ALTER TABLE Production.ProductDescription
DROP COLUMN cs_PDescription
GO