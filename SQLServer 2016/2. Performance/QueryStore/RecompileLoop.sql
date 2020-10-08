DECLARE @sql NVARCHAR(MAX) = N'';

SELECT @sql += N'ALTER TABLE '
  + QUOTENAME(SCHEMA_NAME([schema_id])) 
  + '.' + QUOTENAME(name) + ' ADD fake_column INT NULL;
  ALTER TABLE ' 
  + QUOTENAME(SCHEMA_NAME([schema_id]))
  + '.' + QUOTENAME(name) + ' DROP COLUMN fake_column;'
FROM sys.tables
--WHERE name IN, LIKE, etc.

--PRINT @sql;

-- if the command > 8K, you can see the second chunk e.g.

--PRINT SUBSTRING(@sql, 8001, 8000);

EXEC sp_executesql @sql;