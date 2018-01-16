USE AdventureWorks2016
GO
CREATE TRIGGER [humanresources].[SalaryMonitor] ON [humanresources].[employeepayhistory]
AFTER UPDATE
AS
declare @oldrate money
, @newrate money
, @empid integer
, @msg nvarchar(4000)
select @oldrate = d.rate
from deleted d
select @newrate = i.rate, @empid = i.BusinessEntityID
from inserted i
IF @oldrate*1.20 < @newrate
BEGIN
SET @msg = 'Employee '+CAST(@empid as varchar(50))+' pay rate increased more than 20%'
EXEC sp_audit_write @user_defined_event_id = 27 ,
@succeeded = 1
, @user_defined_information = @msg;
END
GO