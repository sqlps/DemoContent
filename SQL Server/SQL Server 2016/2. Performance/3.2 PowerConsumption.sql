Source: https://github.com/Microsoft/sql-server-samples/tree/master/samples/applications/iot-smart-grid

-- =====================================================================================================
-- Step 1) DB Setup	
-- =====================================================================================================
-- Make sure you create a new PowerConsumption DB


-- =====================================================================================================
-- Step 2) Run the workload
-- =====================================================================================================
-- C:\Demos\SQLServer 2016\Hybrid Cloud Capabilities\In-Memory Enhancements\PowerConsumption.lnk

-- =====================================================================================================
-- Step 3) Stop and open the PBI Report
-- =====================================================================================================

-- ===================================
-- Step 4) Let's have a look at the data
-- ===================================

Use PowerConsumption
Go
Select min(measurementdate)'Min MeasurementDate', max(measurementdate) 'Max MeasurementDate', count (*) 'RecordCount' from MeterMeasurement
-- OMG WHERE ARE MY MEASUREMENTS????

-- 3. Open SSMS and show the table

