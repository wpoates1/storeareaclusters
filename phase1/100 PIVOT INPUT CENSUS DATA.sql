DECLARE projectId STRING;
DECLARE datasetName STRING;
DECLARE tableName STRING;
DECLARE fqTable STRING;
DECLARE sPivotList STRING;
DECLARE sPivotColumns STRING;
DECLARE colPivot STRING;
DECLARE colID STRING;
DECLARE colValue STRING;
DECLARE colPrefix STRING;
DECLARE colPivotDataType STRING;
DECLARE quoteChar STRING;

-- Set the parameter values
SET projectId = 'gdms-demo-20230201';
SET datasetName = 'census2021';
SET tableName = 'TS044_Accommodation';
SET fqTable = CONCAT("`", projectId, ".", datasetName, ".", tableName, "`");
SET colPivot = 'Accommodation_type__8_categories__Code';
SET colID = 'Output_Areas';
SET colValue = 'Observation';
SET colPrefix = 'TS044Code';

-- Get the data type of the colPivot column
EXECUTE IMMEDIATE "SELECT data_type FROM " || projectId || "." || datasetName || ".INFORMATION_SCHEMA.COLUMNS WHERE table_name = '" || tableName || "' AND column_name = '" || colPivot || "'" INTO colPivotDataType;

-- Set the quote character based on the data type
SET quoteChar = (CASE WHEN colPivotDataType = 'STRING' THEN '"' ELSE '' END);

-- CONVERT THE UNIQUE VALUES TO PIVOT ON INTO A COMMA DELIMITED STRING
EXECUTE IMMEDIATE "SELECT STRING_AGG(CONCAT('" || quoteChar || "', CAST(" || colPivot || " AS STRING), '" || quoteChar || "'), ',') FROM (SELECT DISTINCT " || colPivot || " FROM " || fqTable || ")" INTO sPivotList;

-- INSERT THE COMMA-DELIMITED STRING IN THE QUERY 'IN' CLAUSE
-- NB IN THIS INSTANCE AN EXTRA 'WITH' STEP IS INCLUDED AS THERE SEEMED TO BE A PROBLEM WITH LONG COLUMN NAMES
EXECUTE IMMEDIATE "CREATE TABLE " || CONCAT("`", projectId, ".", datasetName, ".PVT_", tableName, "`") || " AS WITH prePivot AS (SELECT " || colID || ", " || colPivot || ", " || colValue || " FROM " || fqTable || ") SELECT * FROM prePivot PIVOT (SUM(" || colValue || ") " || colPrefix || " FOR " || colPivot || " IN (" || sPivotList || "))";


