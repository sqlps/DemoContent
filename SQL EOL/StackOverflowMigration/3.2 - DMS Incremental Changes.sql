-- ============================================
-- Step 1) Create backup for PostHistory
-- ============================================
DROP table PostHistory_Backup
go

Select * into PostHistory_backup from [pankajtsp].StackOverFlowEE.dbo.PostHistory
go
-- ============================================
-- Step 2) Generate some new recrods
-- ============================================
DELETE From PostHistory
GO

SET IDENTITY_INSERT PostHistory ON
GO

Insert into PostHistory(id, PostHistoryTypeId, PostId, RevisionGUID, CreationDate, IPAddress, UserId, Comment, Text, UserDisplayName, UserEmail, UserWebsiteUrl, ApplicationId)
Select id, PostHistoryTypeId, PostId, RevisionGUID, CreationDate, IPAddress, UserId, Comment, Text, UserDisplayName, UserEmail, UserWebsiteUrl, ApplicationId  from PostHistory_backup


select * from PostHistory
