--1 Create the Credential
Use ElasticDBQuery --Shell Database for reporting
GO
CREATE MASTER KEY ENCRYPTION BY PASSWORD = 'P@ssw0rd';

--SQL Login must exist on all servers where the shards exist
CREATE DATABASE SCOPED CREDENTIAL ElasticDBQueryCred
WITH IDENTITY = 'pankaj',
SECRET = 'P@ssw0rd';

--Create Connection to ShardMap: This fails since only v12 supports SHARD_MAP_MANAGER
CREATE EXTERNAL DATA SOURCE MyElasticDBQueryDataSrc WITH
  (TYPE = SHARD_MAP_MANAGER,
  LOCATION = 'PankajTSP-SQL01',
  DATABASE_NAME = 'ElasticScaleStarterKit_ShardMapManagerDb',
  CREDENTIAL = ElasticDBQueryCred,
   SHARD_MAP_NAME = 'CustomerIDShardMap'
) ;
