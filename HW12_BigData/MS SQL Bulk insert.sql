SET STATISTICS TIME ON

DECLARE @filename varchar(256),@path varchar(256);
SET @Path = 'f:\Ó÷¸áà\PostgreSQL\ts_otus\';

--CREATE TABLE taxi_252 (
--  unique_key text 
--, taxi_id text 
--, trip_start_timestamp Smalldatetime 
--, trip_end_timestamp Smalldatetime
--, trip_seconds int 
--, trip_miles decimal(18,2)
--, pickup_census_tract bigint 
--, dropoff_census_tract bigint 
--, pickup_community_area int
--, dropoff_community_area int 
--, fare decimal(18,2) 
--, tips decimal(18,2)
--, tolls decimal(18,2)
--, extras decimal(18,2) 
--, trip_total decimal(18,2) 
--, payment_type nvarchar(50) 
--, company nvarchar(150) 
--, pickup_latitude decimal(18,8) 
--, pickup_longitude decimal(18,8) 
--, pickup_location nvarchar(50) 
--, dropoff_latitude decimal(18,8) 
--, dropoff_longitude decimal(18,8) 
--, dropoff_location nvarchar(50)
--);

--CREATE TABLE #Path (
--       id int IDENTITY(1,1)
--      ,subdirectory nvarchar(512)
--      ,depth int
--      ,isfile bit);
--INSERT #Path (subdirectory,depth,isfile) EXEC master.sys.xp_dirtree @Path,1,1;

DECLARE _cursor CURSOR FOR SELECT subdirectory FROM #Path WHERE isfile = 1 AND RIGHT(subdirectory,4) = '.csv' ORDER BY subdirectory;
OPEN _cursor
FETCH NEXT FROM _cursor INTO @filename
WHILE @@FETCH_STATUS = 0
BEGIN

DECLARE @p nvarchar(256), @SQL nvarchar(2000), @c nvarchar(4), @f nvarchar(1), @r nvarchar(2) ;
SET @p = '' + @path+@filename + '';
SET @SQL = 'BULK INSERT dbo.taxi_252
FROM ' + QUOTENAME(@p, CHAR(39)) + '
WITH (FORMAT = ''CSV''
      , FIRSTROW=2
      , FIELDTERMINATOR = '',''
      , ROWTERMINATOR = ''0x0a''
	  );'
EXEC(@SQL)

FETCH NEXT FROM _cursor INTO @filename

END
CLOSE _cursor;
DEALLOCATE _cursor;

--DROP TABLE #Path;
