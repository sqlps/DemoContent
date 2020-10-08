Select 'DROP Table '+ name
 FROM sys.tables WHERE type = 'U' and is_ms_shipped = 0


 Select 'DELETE FROM '+ name
 FROM sys.tables WHERE type = 'U' and is_ms_shipped = 0
