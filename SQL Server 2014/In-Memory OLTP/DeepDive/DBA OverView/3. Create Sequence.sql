-- Create Sequence, Insert record
--

USE [IMOLTP_Demo]
GO

CREATE SEQUENCE dbo.IMOLSeq START WITH 10 INCREMENT BY 2;
GO

INSERT IMOLTP_Tbl1 (CustomerSeq, Firstname, Lastname, Email, OrderDate)
    VALUES (NEXT VALUE FOR IMOLSeq, 'Walter','White', 'Walter.White@BB.com', SysDateTime());

Go 10

Select * from IMOLTP_Tbl1
where CustomerSeq IS NOT NULL
order by 1
Go
