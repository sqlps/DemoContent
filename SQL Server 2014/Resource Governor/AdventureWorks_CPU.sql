USE AdventureWorks2008R2;
GO
--Hey look at me drive CPU
select * from Production.Product P
CROSS Join Production.ProductCategory
CROSS JOIN Production.ProductDescription
Where P.Name Not Like '%Nut%' and  ProductNumber not in ('HN-3816','CS-6583','RW-M928')
Go


