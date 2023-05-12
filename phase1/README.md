# Phase 2 - Preparing Data Inputs

## Stores Data
In this example, we are starting with a prepared list of stores, giving the location of 160 outlets of a UK retailer. The list has been truncated to include only England and Wales, reflecting the coverage of the ONS census data. Including data for Scotland and Northern Ireland is an obvious extension task. In this instance, the process for preparing this list was:
- web-scraping the addresses of the stores. I used Microsoft PowerAutomate for this, but numerous alternatives are available
- a bit of data tidying up - the scraper output had mis-aligned columns and other annoying issues. Again, sticking with the use of desktop tools in a corporate environment, I used PowerQuery in Excel for a lot of the work. This yielded a list of the stores, with their postal addresses.
-  the final step is geocoding the addresses to apply a latitude/longitude co-ordinates. There are numerous approaches to this, including the official National Statitistics Postcode Lookup (NSPL) dataset. A simpler approach however is to use the marvelous [Doogal](https://www.doogal.co.uk) website of Chris Bell, specifically the [Batch Geocoder](https://www.doogal.co.uk/BatchGeocoding). This fantastically helpful tool gives brilliant set of results for our purposes here. Thanks Chris!

This process yielded a CSV file with nicely formatted addresses, co-ordinates for the postcodes and also a few other additional geography features that may come in handy.


## Census Data - Demographic Data Apprach 1: Directly Sourced from ONS
### Sourcing the Data
Working with the Census data is broadly a straightforward process. There are however a couple of minor frustrations for those of us who are seeking to work directly with a broad range of data, as ONS' web-site is targetted more towrads topic-specific reports and analysis. Finding datasets to download requires navigating through a heirarchy of pages and reports and then working through a wizard-style helper tool.

The data used for this demo comes from 5 tables of Census Outputs, of which 4 were extracted from the ONS Website:

|ONS Table|Contents|Link|
|---------|--------|----|
|TS001|Number of usual residents in households and communal establishments|https://www.ons.gov.uk/datasets/TS001/editions/2021/versions/3/filter-outputs/ebb68985-e5d8-4639-8731-c95d6b2365c6#get-data|
|TS044|Accommodation Type|https://www.ons.gov.uk/datasets/TS044/editions/2021/versions/1/filter-outputs/04dbdbee-80f7-4cee-8fb5-afad4f9c4830#get-data|
|TS062|National Statistics Socio-economic Classification (NS-SEC)|https://www.ons.gov.uk/datasets/TS062/editions/2021/versions/1/filter-outputs/b5ee179d-407e-44c9-8a80-1ea895422f40#get-data|
|TS063|Occupation|https://www.ons.gov.uk/datasets/TS063/editions/2021/versions/3/filter-outputs/6cd92b0d-0a9a-4b8c-807f-01d037819467#get-data|
|TS066|Economic activity status|https://www.ons.gov.uk/datasets/TS066/editions/2021/versions/3/filter-outputs/dedf44d4-324e-4ad2-bbfb-cbf2ba2aa34b#get-data|

Each of these tables was downloaded as a CSV file, in which the contects are structured following a normalised form:

```
Output Areas Code,Output Areas,Residence type (2 categories) Code,Residence type (2 categories),Observation
E00074340,E00074340,1,Lives in a household,356
E00074340,E00074340,2,Lives in a communal establishment,0
E00074341,E00074341,1,Lives in a household,335
E00074341,E00074341,2,Lives in a communal establishment,0
E00074342,E00074342,1,Lives in a household,341
E00074342,E00074342,2,Lives in a communal establishment,35
E00074343,E00074343,1,Lives in a household,235
E00074343,E00074343,2,Lives in a communal establishment,0
E00074344,E00074344,1,Lives in a household,229
E00074344,E00074344,2,Lives in a communal establishment,0
E00074345,E00074345,1,Lives in a household,267
E00074345,E00074345,2,Lives in a communal establishment,0
E00074346,E00074346,1,Lives in a household,243
E00074346,E00074346,2,Lives in a communal establishment,0
E00074347,E00074347,1,Lives in a household,333
E00074347,E00074347,2,Lives in a communal establishment,0
E00074348,E00074348,1,Lives in a household,204
E00074348,E00074348,2,Lives in a communal establishment,2
E00074349,E00074349,1,Lives in a household,307
E00074349,E00074349,2,Lives in a communal establishment,0
```

### Loading the data into BigQuery
The simplest data loading approach is to load the tables directly into the BigQuery dataset, using Schema Autodetect. The other straightforward is to add a file to a Google Cloud Storage bucket and then loading from there - that approach has the advantage of ensring the raw data is available for future use. The parentheses and spaces in the columns names were replaced by underscore characters, making for long column names that are not idea for SQL queries. But other than that, the data should load succesfully.

There is the potential to script and automate this process. This is easily accomplished by using the Google SDK on the desktop command line or on the Google Cloud Console. Python code can also do the job and with a CSV table in Cloud Storage, you can actually use SQL as well. However given the small number of tables involved, the manual approach is the most appropriate.


### Reformatting and Pivoting - Create New Table for Output
In order to deliver the cluster, the first part of the process is to flatten / de-normalise / pivot the data, so that each Output Area is on it's own row. The `PIVOT` function in BigQuery is a relatively new addition, and does simplify this task somewhat, but there are a few wrinkles - see below. The approach to the query makes extensive use of `EXECUTE IMMEDIATE` which allows for the construction of parameterised SQL. It's also constructed as a multi-statement query, which may mean it looks a bit daunting, but hopefully makes sense with a litlte bit of scrutiny. The final output is a new Table, containing the pivotted results.

#### PIVOT function - care needed
- The `PIVOT` function in BigQuery a needs string containing the list of the features to convert to columns. In this instance, we generate that string by querying for all the unique values: each of which will become a column in the output. 

- If the unique values are strings, then BigQuery expects them to be quote-wrapped, whereas numbers (like the 'Code' used in this case here) are unwrapped. The variable type (and hence the quote character needed) is determined by inspecting the table's `INFORMATION_SCHEMA`.

- A helpful aspect of BigQuery's PIVOT function is the Prefix capability, where you can specifcy a string to be pre-pended to each of the column names. As we will be working with multiple Census tables and have chosen to use the numercial code rather than the actual description of the variable, we use the table name, so that the columns will be `OutputArea` followed by `TS044Code1`, `TS044Code2`, `TS044Code3` etc. etc.

- This may or may not be necessary, but to get this function to work, in the final PIVOT query, I used a pre-query to select only the 3 necessary columns from the underlying census table

So the PIVOT action therefore requires a multi-stage process: get the data type to determine quote-wrapping, constructing the string list of columns to pivot (with quote-wrapping as required), then constructing the final query. The code below (and in the repository) completes all these steps for a given input Census table. Change the values in the variables block to align to your particular project: the example below has been set for Table TS044 which gives results for the accommdoation type.


```SQL
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

-- CHANGE THESE VARIABLES AS APPROPRIATE
SET projectId = _PROJECT_;
SET datasetName = _DATASET_;
SET tableName = 'TS044_Accommodation';
SET colPrefix = 'TS044Code';
SET colPivot = 'Accommodation_type__8_categories__Code';
SET colID = 'Output_Areas';
SET colValue = 'Observation';

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
```


## Census Data - Demographic Data Approach 2: NOMIS pre-pivotted
The PIVOT function created above is a very useful tool in BigQuery, and by using the approach above, it is relatively quick and easy. As this work was being prepared however (Q1 2023), the NOMIS service releaed their bulk data downloads for the Census 2021 results. These are provided in a pre-pivotted form, in ZIP files at https://www.nomisweb.co.uk/sources/census_2021_bulk. Just download the zip, extract and locate the CSV labelled "-oa" for the output area level data. Generally the largest file.

Using these files avoids entirely the need for the intial pivot function and in a lot of cases. Just create a new table in BigQuery by uploading this CSV. The only downside of this approach is that the column headers created by this approach are extremely long and don't follow the nice convention using the Code prefix above.

For the purposes of this demonstration, one NOMIS format table was loaded:

|ONS Table|Contents|Link|
|---------|--------|----|
|TS007A|Age by five-year age bands|https://www.nomisweb.co.uk/output/census/2021/census2021-ts007a.zip|

# Conflating the Census Tables
To undertake the modelling, all the separate - now pivotted - it is easier to compile all the data into a single, wide table containing all the parameters for every Output Area. This 'big wide table' is a typical approach of working with BigQuery and avoids lots of subsequent join operations.

## Method 1: SELECT and JOIN
There are a number of approaches to generating this big, wide table. The simplest approach is just to run a big SELECT query with a join on the OutputAreaID. The SQL statement below does that, for three census tables. Note that in this instance that `TS055_Bedrooms` has been loaded directly from NOMIS rather than having being created using the PIVOT method and the query excludes a couple of other fields from the conflated table.

```SQL
-- CHANGE THE PROJECT AND DATASET VALUES BELOW AND IN THE JOIN STATEMENTS BELOW
CREATE OR REPLACE TABLE _PROJECT_._DATASET_.PVT2_Conflated AS
SELECT
  T1.geography_code,
  T1.* EXCEPT(date, geography, geography_code),
  T2.* EXCEPT(Output_Areas),
  T3.* EXCEPT(Output_Areas)
FROM
  _DATASET_.TS055_Bedrooms AS T1
JOIN
  _DATASET_.PVT_TS044_Accommodation AS T2
ON
  T1.geography_code = T2.Output_Areas
JOIN
  _DATASET_.PVT_TS062_NSSEC AS T3
ON
  T1.geography_code = T3.Output_Areas;
```

## Method 2: Add New Columns to a pre-existing Table
The first approach regenerates the table from scratch each time the query is run. This becomes problematic if there are values in the table that you actually want to preserve. In that case, the requirment is to undertake two actions on an underlying base table: 
- Add empty columns of the right type
- Populating the content of those columns

### Adding empty columns
This SQL iterates over the columns in a source table, collects the ones required using the `INFORMATION SCHEMA` and then adds them in turn to a target table using an `ALTER TABLE ADD COLUMN` DDL statement. Somewhat annoyingly there is a limit of 5 change instructions per 10 seconds. The code below uses an interation loop to ensure that this limit isn't exceeded. If there are more than 5 columns to add, then the script will need to be run multiple times - waiting at least 10 seconds between each execution!   

```SQL
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
```

The next step is then to populate the columns:

```SQL
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
```

