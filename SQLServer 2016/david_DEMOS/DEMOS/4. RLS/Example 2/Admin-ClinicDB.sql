/****** Check mapping for patients to nurse  ******/
SELECT TOP (1000) [ApplicationUser_Id]
      ,[Patient_PatientID]
  FROM [dbo].[ApplicationUserPatients]

/****** Manually change mapping of patients to nurse  ******/
  UPDATE [ApplicationUserPatients]
  SET ApplicationUser_Id = '82a1a7c9-31fa-4304-bedc-803655b73aba'
  WHERE Patient_PatientID = 19

/****** Map existing patient to nurse  ******/
INSERT INTO [dbo].[ApplicationUserPatients]
           ([ApplicationUser_Id]
           ,[Patient_PatientID])
     VALUES
           ('82a1a7c9-31fa-4304-bedc-803655b73aba'
           ,26)
GO

