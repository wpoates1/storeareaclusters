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

-- CHANGE THESE TO MATCH YOUR PROJECT AND DATASET
SET projectId = _PROJECT_;
SET datasetName = _DATASET_;

-- APPLY EACH OF THESE IN TURN BY COMMENTING AND UNCOMMENTING
--   THIS WILL CREATE NEW PIVOTTED OUTPUT FOR EACH OF THE INPUT TABLES
SET tableName = 'TS001';
SET colPivot = 'Residence_type__2_categories__Code';

-- SET tableName = 'TS044';
-- SET colPivot = 'Accommodation_type__8_categories__Code';

-- SET tableName = 'TS062';
-- SET colPivot = 'National_Statistics_Socio_economic_Classification__NS_SeC___10_categories__Code';

-- SET tableName = 'TS063';
-- SET colPivot = 'Occupation__current___10_categories__Code';

-- SET tableName = 'TS066';
-- SET colPivot = 'Economic_activity_status__20_categories__Code';

-- THESE ARE THE SAME FOR EACH INPUT TABLE BE FIXED FOR EACH
SET colID = 'Output_Areas';
SET colValue = 'Observation';
SET colPrefix = CONCAT(tableName,'Code');


SET fqTable = CONCAT("`", projectId, ".", datasetName, ".", tableName, "`");

-- 1. GET THE DATA TYPE FOR THE VALUES THAT WILL FORM THE COLUMN HEADRES IN THE OUPUT
--   SET THE QUOTE WRAPPER TO "" IF ITS STRING TYPE
EXECUTE IMMEDIATE "SELECT data_type FROM " || projectId || "." || datasetName || ".INFORMATION_SCHEMA.COLUMNS WHERE table_name = '" || tableName || "' AND column_name = '" || colPivot || "'" INTO colPivotDataType;
SET quoteChar = (CASE WHEN colPivotDataType = 'STRING' THEN '"' ELSE '' END);

-- 2. CONVERT THE UNIQUE VALUES TO PIVOT ON INTO A COMMA DELIMITED STRING
EXECUTE IMMEDIATE "SELECT STRING_AGG(CONCAT('" || quoteChar || "', CAST(" || colPivot || " AS STRING), '" || quoteChar || "'), ',') FROM (SELECT DISTINCT " || colPivot || " FROM " || fqTable || ")" INTO sPivotList;

-- 3. DO THE ACTUAL PIVOT USING THE LIST OF COLUMN NAMES.
--  THIS USES A PRE-SELECTION OF ONLY THE COLUMNS NEEDED
--  RESULTS ADDED TO A NEW TABLE
EXECUTE IMMEDIATE "CREATE TABLE " || CONCAT("`", projectId, ".", datasetName, ".PVT_", tableName, "`") || " AS WITH prePivot AS (SELECT " || colID || ", " || colPivot || ", " || colValue || " FROM " || fqTable || ") SELECT * FROM prePivot PIVOT (SUM(" || colValue || ") " || colPrefix || " FOR " || colPivot || " IN (" || sPivotList || "))";
