-- =====================================================================================================
-- Step 1) View CMK and CEK
-- =====================================================================================================
USE [WideWorldImporters]
CREATE COLUMN MASTER KEY [WWI_ColumnMasterKey]
WITH
(
	KEY_STORE_PROVIDER_NAME = N'MSSQL_CERTIFICATE_STORE',
	KEY_PATH = N'CurrentUser/My/163F7980DD02EDC5C8CC1F7D632D30571AD4E13D'
)
GO

CREATE COLUMN ENCRYPTION KEY [WWI_ColumnEncryptionKey]
WITH VALUES
(
	COLUMN_MASTER_KEY = [WWI_ColumnMasterKey],
	ALGORITHM = 'RSA_OAEP',
	ENCRYPTED_VALUE = 0x016E000001630075007200720065006E00740075007300650072002F006D0079002F003100360033006600370039003800300064006400300032006500640063003500630038006300630031006600370064003600330032006400330030003500370031006100640034006500310033006400951F339DFCE8B2F105AB9E4BDB1C4921A04A68BA4DE05DE01C52395F957B2C83EF7DAE53EF656A70D9263986342A901B8FC2DFEAF5923226F4FC5832C0FF1A9125FA58A039F39DD8040DDC334E5D84E1B21A3D3E5C577A8C1A4C910F8A81DE26608C21953D96CC7507D6F7C10018A72FBAA22ADBA47984F648D5C9400955CD0E729D371A8F036472D9366C8F602474E6CBDEBAB37021AFF5D19E529EDC0693C8784739A79A175A7193A550C3FAB3C2A3E610D5A5FF234F02B6AE055C4F27AA7A6420BB3079A6A558F50AEF7A11FC4CD41BF8598BA96709714D6C4562702005B69CB0C332119132E8C0F1FE0CB1FACEEE783C01EFB6DAD808E779847907B54D247417B3B767EC3EED04148891287072FDDB15E60CA7545316BD35045067771AFF452B2A483D93F841A7DA1108B5A5106756A25AEA1978E2E58A444DDC9A46EA2B245C30EC087F251E3F21B94C0660EFCA7E53C829F5EE6204107CC7F3F77C60E49F2687CAC18DE4A14E0234AB1903CEDFB0526C0F847F5D6C50C17F3EA35E88C039A19DD48D4C46E75EF017F3B369FB6B9A9333A6D4BCA3568A3C688BA85FBFCF81DAC0C7FA2297C9E6F91A20668C3F6A24F1E6711CFC2B30FE879E2A5310F28C11C8536E929E5C63C94EC7BF8ED3F1DC28C5557FC0F8286C89CEDCC7BF4ABF16CA5C0681FBE490B0DACC0055C8CE20879256FCC0D4B4E3E579C3F411220EF18A
)
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

--Kick off workload E:\Demos\SQL Server 2016 - WWI\Security\PopulateAlwaysEncryptedData.exe

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

--Can i do a simple filter
SELECT * FROM Purchasing.Supplier_PrivateDetails 
Where NationalId = '30023258'

-- ============================================
-- Step 8) Parameterize your queries in SSMS
-- ============================================
-- Need to paramertize it and SSMS 17.0 with Parameterization for AE enabled see: https://blogs.msdn.microsoft.com/sqlsecurity/2016/12/13/parameterization-for-always-encrypted-using-ssms-to-insert-into-update-and-filter-by-encrypted-columns/

DECLARE @NationalID nvarchar(30) = '30023258'
Select *
from Purchasing.Supplier_PrivateDetails 
where NationalID = @NationalID
go
-- ============================================
-- Step 6) Insert some data
-- ============================================
Truncate Table purchasing.Supplier_PrivateDetails --Only 13 SupplierIDs

Declare @NationalID nvarchar(30)= '599914575',
		@CCNum nchar(30) = '1234-4556-7899-0124',
		@ExpiryDate nchar(5) ='12/99'
Insert Purchasing.Supplier_PrivateDetails  (SupplierID, NationalID, CreditCardNumber, ExpiryDate)
values(1, @NationalID, @CCNum, @ExpiryDate)

Select *
from Purchasing.Supplier_PrivateDetails 

GO

