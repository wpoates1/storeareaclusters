# Phase 2 - Preparing Data Inputs

## Stores Data
In this example, we are starting with a prepared list of stores, giving the location of 160 outlets of a UK retailer. The list has been truncated to include only England and Wales, reflecting the coverage of the ONS census data. Including data for Scotland and Northern Ireland is an obvious extension task. In this instance, the process for preparing this list was:
- web-scraping the addresses of the stores. I used Microsoft PowerAutomate for this, but numerous alternatives are available
- a bit of data tidying up - the scraper output had mis-aligned columns and other annoying issues. Again, sticking with the use of desktop tools in a corporate environment, I used PowerQuery in Excel for a lot of the work. This yielded a list of the stores, with their postal addresses.
-  the final step is geocoding the addresses to apply a latitude/longitude co-ordinates. There are numerous approaches to this, including the official National Statitistics Postcode Lookup (NSPL) dataset. A simpler approach however is to use the marvelous [Doogal](https://www.doogal.co.uk) website of Chris Bell, specifically the [Batch Geocoder](https://www.doogal.co.uk/BatchGeocoding). This fantastically helpful tool gives brilliant set of results for our purposes here. Thanks Chris!

This process yielded a CSV file with nicely formatted addresses, co-ordinates for the postcodes and also a few other additional geography features that may come in handy.


## Census Data - Demographic Data (Part 1)
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
The data loading process followed the very straightforward approach of manually loading each file to a Google Cloud Storage bucket and then manually loading the CSV data into BigQuery as a new table. The parentheses and spaces in the columns names were replaced by underscore characters, making for long column names that are not idea for SQL queries. But other than that, the data loaded succesfully.

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
SET projectId = 'MY PROJECT NAME';
SET datasetName = 'MY DATASET NAME';
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
