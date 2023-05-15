# Phase 1 - Preparing Data Inputs

## Stores Data
In this example, we are starting with a prepared list of stores, giving the location of 160 outlets of a UK retailer. The list has been truncated to include only England and Wales, reflecting the coverage of the ONS census data. Including data for Scotland and Northern Ireland is an obvious extension task. In this instance, the process for preparing this list was:
- web-scraping the addresses of the stores. I used Microsoft PowerAutomate for this, but numerous alternatives are available
- a bit of data tidying up - the scraper output had mis-aligned columns and other annoying issues. Again, sticking with the use of desktop tools in a corporate environment, I used PowerQuery in Excel for a lot of the work. This yielded a list of the stores, with their postal addresses.
-  the final step is geocoding the addresses to apply a latitude/longitude co-ordinates. There are numerous approaches to this, including the official National Statitistics Postcode Lookup (NSPL) dataset. A simpler approach however is to use the marvelous [Doogal](https://www.doogal.co.uk) website of Chris Bell, specifically the [Batch Geocoder](https://www.doogal.co.uk/BatchGeocoding). This fantastically helpful tool gives brilliant set of results for our purposes here. Thanks Chris!

This process yielded a CSV file with nicely formatted addresses, co-ordinates for the postcodes and also a few other additional geography features that may come in handy.

### Uploading to BigQuery
First, if you haven't done so alread, create a Google Cloud Storage bucket to hold all these files. Use the default settings - including accepting the US Multi Region (the default setting) for location. This [guide](https://www.techrepublic.com/article/how-to-create-a-file-storage-bucket-in-google-cloud-platform/) has a useful tutorial if you are unsure about this. Upload the stores.csv file to this bucket - you can drag and drop from Explorer if you are using Chrome! Otherwise, use the Upload function in the console.

Next upload this CSV file to BigQuery to create our dataset. If you're unsure about how to do this, take a look at Google's [help document](https://cloud.google.com/bigquery/docs/loading-data-cloud-storage-csv#loading_csv_data_into_a_table). The data here is all nicely formatted and will load just by accepting the defaults, including schema autodetect. Again, to keep life simple, accept the default location as US Multi-region for the new table. 

To recap - detailed instructions for to create the table:
- In the BigQuery Explorer pane, click the three dots next to your project name. Create a new dataset in your project, selecting US multi-region as the location. Use `stores` as the table name to allow the queries in the later phases to run succesfully;
- Now that you've created your dataset, add the tables from cloud storage by pressing + ADD in Explorer, or the 3 dots next to the dataset name;

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
Download the 5 files to your local machine and each to your Google Cloud Storage. From there, they can be added as tables into your dataset in BigQuery. Use the same approach used for the stores table earlier, but in this case please use the naming convention TS0nn for the table names - it will make the later SQL below easier!

Following these steps, you should end up with 5 tables in your dataset: `TS001`, `TS044`, `TS062`, `TS063`, `TS066`. Take a look at the contents of each table and you'll see that it is data in normal form, with a row for each combination of output area and variable. The parentheses and spaces in the columns names were replaced by underscore characters during import, making for long column names that are not idea for SQL queries. But other than that, the data should load succesfully.


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
```


## Census Data - Demographic Data Approach 2: NOMIS pre-pivotted
The PIVOT function created above is a very useful tool in BigQuery, and by using the approach above, it is relatively quick and easy. As this work was being prepared however (Q1 2023), the NOMIS service releaed their bulk data downloads for the Census 2021 results. These are provided in a pre-pivotted form, in ZIP files at https://www.nomisweb.co.uk/sources/census_2021_bulk. Just download the zip, extract and locate the CSV labelled "-oa" for the output area level data. Generally the largest file.

For this demo, we have used only one of the tables in this format:

|ONS Table|Contents|Link|
|---------|--------|----|
|TS007A|Age by five-year age bands|https://www.nomisweb.co.uk/output/census/2021/census2021-ts007a.zip|


Using these files avoids entirely the need for the intial pivot function and in a lot of cases. Just create a new table in BigQuery by uploading this CSV via Google Cloud Storage as per the method above. Call it `TS007`. The only downside of this approach is that the column headers created by this approach are extremely long and don't follow the nice convention using the Code prefix above. Note that these are also 


# Conflating the Census Tables
For the next stage of the work, we need to pull together all the data from the 6 files that have been loaded. The SQL below selects all the content and uses it to create a new table: `PVT_Conflated`

```SQL
-- CONFLATE THE TABLES INTO A SINGLE PVT_CONFLATED TABLE
--  USING THE GEOGRAPHY CODE FOR THE JOIN
CREATE OR REPLACE TABLE _PROJECT_._DATASET_.PVT_Conflated AS
SELECT
  T1.*,
  T2.* EXCEPT(Output_Areas),
  T3.* EXCEPT(Output_Areas),
  T4.* EXCEPT(Output_Areas),
  T5.* EXCEPT(Output_Areas),
  T6.* EXCEPT(date, geography, geography_code)    -- THE TABLE LOADED DIRECT FROM NOMIS
FROM
  _DATASET_.PVT_TS001_Residents AS T1    -- THE BASE TABLE

-- THE TABLES BELOW ARE JOINED TO THE BASE TABLE
JOIN
  _DATASET_.PVT_TS044 AS T2
ON
  T1.Output_Areas = T2.Output_Areas
JOIN
  _DATASET_.PVT_TS062 AS T3
ON
  T1.Output_Areas = T3.Output_Areas
JOIN
  _DATASET_.PVT_TS063 AS T4
ON
  T1.Output_Areas = T4.Output_Areas
JOIN
  _DATASET_.PVT_TS066 AS T5
ON
  T1.Output_Areas = T5.Output_Areas
JOIN
  _DATASET_.TS007 AS T6
ON
  T1.Output_Areas = T6.geography_code;
```

