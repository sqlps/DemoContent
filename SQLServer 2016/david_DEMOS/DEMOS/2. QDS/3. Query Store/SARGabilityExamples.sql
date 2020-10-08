-- Query  Optimization
-- SARGability

--create tables 
IF object_id(N'dbo.ProductDescriptionSARG') IS NOT NULL
          DROP TABLE dbo.ProductDescriptionSARG;

GO
CREATE TABLE dbo.ProductDescriptionSARG
(
          [ProductDescriptionID] INT              NOT NULL,
          [Description]          NVARCHAR (400)   NOT NULL,
          [rowguid]              UNIQUEIDENTIFIER NOT NULL,
          [ModifiedDate]         DATETIME         NOT NULL,
          [DescriptionSingle]    VARCHAR (400)    NULL,
          CONSTRAINT [PK_ProductDescription_ProductDescriptionID] PRIMARY KEY CLUSTERED ([ProductDescriptionID] ASC)
);

GO
CREATE NONCLUSTERED INDEX [IXProductDescriptionSARG_Description]
          ON [dbo].[ProductDescriptionSARG]([Description] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_ProductDescriptionSARG_ModifiedDate]
          ON [dbo].[ProductDescriptionSARG]([ModifiedDate] ASC, [Description] ASC);

GO
CREATE NONCLUSTERED INDEX [IX_ProductDescriptionSARG_DescriptionSingle]
          ON [dbo].[ProductDescriptionSARG]([DescriptionSingle] ASC, [ModifiedDate] ASC);

GO
INSERT INTO dbo.ProductDescriptionSARG
SELECT *,
       CAST ([Description] AS VARCHAR (400))
FROM   AdventureWorks2014.Production.ProductDescription;

GO
UPDATE        dbo.ProductDescriptionSARG
          SET ModifiedDate = CAST (((2013 - ProductDescriptionID % 5) * 10000 + ((ProductDescriptionID % 11) + 1) * 100 + ((ProductDescriptionID) % 27) + 1) AS CHAR (8));

GO
IF object_id('dbo.binaryTable') IS NOT NULL
          DROP TABLE binaryTable;

GO
CREATE TABLE binaryTable
(
          c1 INT         ,
          c2 BINARY (500)
);

SET NOCOUNT ON;
BEGIN TRANSACTION;
DECLARE @x AS INT;

SET @x = 1;

WHILE (@x < 100000)
          BEGIN
                    INSERT  INTO binaryTable
                    VALUES (@x, @x);
                    SET @x = @x + 1;
          END

COMMIT TRANSACTION;

CREATE INDEX idx1
          ON binaryTable(c2);


-- partial strings
-- what is the plan difference?
-- what is the estimate vs. actual rows?
SELECT *
FROM   dbo.ProductDescriptionSARG AS pds
WHERE  pds.Description LIKE '%replacement%';


GO
SELECT *
FROM   dbo.ProductDescriptionSARG AS pds
WHERE  pds.Description LIKE 'replacement%';

-- functions on column
-- keep an eye on the estimate vs. actual rows

--not so good
SELECT *
FROM   dbo.ProductDescriptionSARG AS pds
WHERE  substring(pds.Description, 1, 11) = 'replacement';

--better
SELECT *
FROM   dbo.ProductDescriptionSARG AS pds
WHERE  pds.Description LIKE 'replacement%';

-- playing with dates
SELECT pds.Description,
       pds.ModifiedDate
FROM   dbo.ProductDescriptionSARG AS pds
WHERE  year(pds.ModifiedDate) = 2009;


GO
SELECT pds.Description,
       pds.ModifiedDate
FROM   dbo.ProductDescriptionSARG AS pds
WHERE  pds.ModifiedDate BETWEEN '20090101' AND '20091231';



 -- type conversion
 -- what's in the table?
SELECT TOP 10 *
FROM   dbo.binaryTable;


 -- note the estimated vs. actual rows
 -- note the warning in the first plan
SELECT c2
FROM   dbo.binaryTable
WHERE  c2 > 256;

SELECT c2
FROM   dbo.binaryTable
WHERE  c2 > 0x0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000100;

