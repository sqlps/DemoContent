--Installing R Packages https://msdn.microsoft.com/en-us/library/mt591989.aspx

EXECUTE sp_execute_external_script
       @language = N'R'
, @script = N'OutputDataSet <- data.frame(.libPaths());'
WITH RESULT SETS ((
       [DefaultLibraryName] VARCHAR(MAX) NOT NULL));
GO
-- C:/Program Files/Microsoft SQL Server/MSSQL13.MSSQLSERVER/R_SERVICES/library


  execute sp_execute_external_script    
    @language = N'R'    
  , @script = N' 
	library(detector)
	x <- data.frame(InputDataSet)
	 OutputDataSet <- detect(x);'    
  , @input_data_1 = N'select nationalidnumber,birthdate from AdventureWorks2014.humanresources.Employee'    
  WITH RESULT SETS (([NewColName] char(20) NOT NULL, [Col2] char(20) NULL));

  