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

-- =====================================================================================================
-- Step 1) View CMK and CEK
-- =====================================================================================================
Use WideWorldImporters
GO

--CMK
Select * from sys.column_master_keys
Go

-- CEK
SELECT * FROM sys.column_encryption_keys;
GO

-- =====================================================================================================
-- Step 2) Create encrypted table
-- =====================================================================================================
DROP TABLE IF EXISTS Purchasing.Supplier_PrivateDetails
GO
CREATE TABLE Purchasing.Supplier_PrivateDetails
(
	SupplierID int 
		CONSTRAINT PKFK_Purchasing_Supplier_PrivateDetails PRIMARY KEY
		CONSTRAINT FK_Purchasing_Supplier_PrivateDetails_Suppliers
			FOREIGN KEY REFERENCES Purchasing.Suppliers (SupplierID),
	NationalID nvarchar(30) COLLATE Latin1_General_BIN2
		ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = WWI_ColumnEncryptionKey,
                           ENCRYPTION_TYPE = DETERMINISTIC,
						ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL,
	CreditCardNumber nvarchar(30) COLLATE Latin1_General_BIN2
		ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = WWI_ColumnEncryptionKey,
                           ENCRYPTION_TYPE = RANDOMIZED,
						ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL,
	ExpiryDate nvarchar(5) COLLATE Latin1_General_BIN2
		ENCRYPTED WITH (COLUMN_ENCRYPTION_KEY = WWI_ColumnEncryptionKey,
                           ENCRYPTION_TYPE = RANDOMIZED,
						ALGORITHM = 'AEAD_AES_256_CBC_HMAC_SHA_256') NULL
);
GO
-- =====================================================================================================
-- Step 3) Test Insert
-- =====================================================================================================
INSERT Purchasing.Supplier_PrivateDetails 
	(SupplierID, NationalID, CreditCardNumber, ExpiryDate)
VALUES
	(1, N'93748567', N'7382-5849-2903-2838', N'11/19');
GO
/*
						cmd.CommandText = "INSERT Purchasing.Supplier_PrivateDetails "
                                        + "(SupplierID, NationalID, CreditCardNumber, ExpiryDate) "
                                        + "VALUES (@SupplierID, @NationalID, @CreditCardNumber, @ExpiryDate);";
                        cmd.Parameters.Add(new SqlParameter("@SupplierID", SqlDbType.Int));
                        cmd.Parameters.Add(new SqlParameter("@NationalID", SqlDbType.NVarChar, 30));
                        cmd.Parameters.Add(new SqlParameter("@CreditCardNumber", SqlDbType.NVarChar, 30));
                        cmd.Parameters.Add(new SqlParameter("@ExpiryDate", SqlDbType.NVarChar, 5));
*/
-- Clear the table
TRUNCATE TABLE Purchasing.Supplier_PrivateDetails 

-- =====================================================================================================
-- Step 4) Run client application
-- =====================================================================================================

--Kick off workload C:\Demos\SQL Server 2016 - WWI\Always Encrypted\PopulateAlwaysEncryptedData.exe

-- =====================================================================================================
-- Step 5) View Extended Event Session and validate cannot see any parameters
-- =====================================================================================================

-- =====================================================================================================
-- Step 6) Verify data in table
-- =====================================================================================================
SELECT * FROM Purchasing.Supplier_PrivateDetails ORDER BY SupplierID;
GO

-- =====================================================================================================
-- Step 7) Change connection and re-reun with  Column Encryption Setting=enabled
-- =====================================================================================================
Use WideWorldImporters
GO
SELECT * FROM Purchasing.Supplier_PrivateDetails ORDER BY SupplierID;
GO