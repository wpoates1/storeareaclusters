-- UPDATES COLUMNS FROM AN INDIVIDUAL CENSUS TABLE TO THE MAIN PIVOTED TABLE
--  RELIES ON THE COLUMNS EXISTING. IF THEY NEED TO BE ADDED, THEN USE THE ADD COLUMNS TO PIVOT QUERY
DECLARE projectId STRING;
DECLARE datasetName STRING;
DECLARE sourceTable STRING;
DECLARE targetTable STRING;
DECLARE columnNames ARRAY<STRING>;
DECLARE setClause STRING DEFAULT '';
DECLARE excludedColumns STRING;

-- Set the parameter values
SET projectId = _PROJECT_;
SET datasetName = _DATASET_;
SET sourceTable = 'TS007_Age_Nomis';  -- SOURCE TABLE
SET targetTable = 'PVT_Conflated';   -- TARGET TABLE

-- Set the excluded columns
SET excludedColumns = "'date', 'geography', 'geography_code'";

-- Get the column names from the source table, excluding the 'Output_Areas' column
EXECUTE IMMEDIATE "SELECT ARRAY_AGG(column_name) FROM " || projectId || "." || datasetName || ".INFORMATION_SCHEMA.COLUMNS WHERE table_name = '" || sourceTable || "' AND column_name NOT IN (" || excludedColumns || ")" INTO columnNames;

-- Generate the SET clause for the UPDATE statement
SET setClause = (SELECT STRING_AGG(columnName || ' = source.' || columnName, ', ') FROM UNNEST(columnNames) AS columnName);

-- Perform the UPDATE statement on the target table
EXECUTE IMMEDIATE "UPDATE `" || projectId || "." || datasetName || "." || targetTable || "` AS target SET " || setClause || " FROM `" || projectId || "." || datasetName || "." || sourceTable || "` AS source WHERE target.Output_Areas = source.geography_code";
