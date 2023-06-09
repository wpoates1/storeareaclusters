DECLARE projectId STRING;
DECLARE datasetName STRING;
DECLARE tableName STRING;
DECLARE targetTable STRING;
DECLARE columnInfoArray ARRAY<STRUCT<column_name STRING, data_type STRING>>;
DECLARE existingColumns ARRAY<STRING>;
DECLARE excludedColumns STRING;
DECLARE i INT64;
DECLARE maxCol INT64;

-- Set the parameter values
SET projectId = _PROJECT_;
SET datasetName = _DATASET_;
SET tableName = 'TS007_Age_NOMIS';  -- SOURCE TABLENAME
SET targetTable = 'PVT_Conflated';  -- TARGET TABLE OF PRE-EXISTING VALUES

-- Set the excluded columns
SET excludedColumns = "'date', 'geography', 'geography_code'";

-- Get the column names and data types from the source table, excluding the specified columns
EXECUTE IMMEDIATE "SELECT ARRAY_AGG(STRUCT(column_name, data_type)) FROM " || projectId || "." || datasetName || ".INFORMATION_SCHEMA.COLUMNS WHERE table_name = '" || tableName || "' AND column_name NOT IN (" || excludedColumns || ")" INTO columnInfoArray;


-- Get the existing column names in the target table
EXECUTE IMMEDIATE "SELECT ARRAY_AGG(column_name) FROM " || projectId || "." || datasetName || ".INFORMATION_SCHEMA.COLUMNS WHERE table_name = '" || targetTable || "'" INTO existingColumns;

-- Remove the columns that already exist in the target table from columnInfoArray
SET columnInfoArray = (SELECT ARRAY_AGG(columnInfo) FROM UNNEST(columnInfoArray) AS columnInfo WHERE columnInfo.column_name NOT IN (SELECT * FROM UNNEST(existingColumns)));

-- Iterate through the columns and add them to the target table using ALTER TABLE ADD COLUMN IF NOT EXISTS, limiting to 5 columns at a time at most
SET maxCol = (SELECT MIN(x) FROM UNNEST([5, ARRAY_LENGTH(columnInfoArray)]) AS x);

SET i = 1;
WHILE (i <= maxCol)
DO
  EXECUTE IMMEDIATE 'ALTER TABLE `' || projectId || '.' || datasetName || '.' || targetTable || '` ADD COLUMN IF NOT EXISTS ' || columnInfoArray[ORDINAL(i)].column_name || ' ' || columnInfoArray[ORDINAL(i)].data_type || ';';
  SET i = i + 1;
END WHILE;
