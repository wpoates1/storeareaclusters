# Phase 2 - Creating the Cluster Input File Using Spatial Join



## Adding Geospatial References
_If you have used the `loadsql.py` routine in pre-requisites, then the `OA21_CENTROIDS` and the `OA21_AREAS` tables will have been loaded for you, so there is no need to manually upload the files in the step below. You can skip the upload part and just run the SQL scripts to create the centroids and to add the values to the main `PVT_Conflated` table._

### Load the table of co-ordinates for Output Area 
In order to conduct the spatial integration, then we need the location of each Output Area. In a really deatiled analysis you might utilise the full polygons each Output Area, but in this case, we can utilise the Population Weighted Centroids which describe a point inside the polygon that is approximately the mid-point of all the recorded addresses. This centroid dataset is available from ONS Geoportal at https://geoportal.statistics.gov.uk/datasets/ons::output-areas-dec-2021-pwc-version-2/about. On this site, they are expressed in Ordnance Survey National Grid Co-ordinates, rather than latitude and longitude, so they need to be converted. This is easily accomplished in Python code using Cloud Shell (or a  notebook etc.) and the script  `add lat and long columns.py` provides this functionality.

To simplify things, this step has already been completed and the resulst are available as `Output_Areas_2021_PWCv2.csv` from the repository above. Just add this to your storage bucket and then create the table `OA21_CENTROIDS` in BigQuery

### Create the Geographical Point Object for Output Areas and for Stores
For the BigQuery geographical functions to operate, it requires data of the `GEOGRAPHY` type to operate with. Although we have the latitude and longitudes of our output areas and of our stores, we need to add a new column to each table, and use the `ST_GEOGPOINT` function to generate this data. The SQL below adds a column and then populates it with the spatial data for the `OA21_CENTROIDS` and the `stores` table.

```SQL
-- ADDS CENTROIDS COLUMN AND CREATES THE SPATIAL POINT DATA
--  FOR BOTH THE OUTPUT AREA DATA AND THE STORES DATA

-- FIRST THE OUTPUT AREAS
ALTER TABLE `_PROJECT_._DATASET_.OA21_CENTROIDS` 
    ADD COLUMN IF NOT EXISTS centroid GEOGRAPHY;

UPDATE `_PROJECT_._DATASET_.OA21_CENTROIDS`
    SET centroid = ST_GEOGPOINT(longitude,latitude) WHERE true;


-- AND NOW THE STORES
ALTER TABLE `_PROJECT_._DATASET_.stores` 
    ADD COLUMN IF NOT EXISTS geom GEOGRAPHY;

UPDATE `_PROJECT_._DATASET_.stores`
    SET geom = ST_GEOGPOINT(longitude,latitude) WHERE true;
```

### Area Statistics for each Output Area 
The other geographical variable that is relevant here is the land area, which then supports the population desnsity figures. Areas form part of the Standard Area Measurement dataset, available in CSV format (zipped) at https://geoportal.statistics.gov.uk/datasets/a488cb8fc9a74accb63cb52961e456ef/about. The file needed is SAM_OA_DEC_2021_EW.csv from within the zip resource. I've loaded it as the `OA21_AREAS` table, again using the same process of uploading to the storage bucket. **Again, to save time, I've added this CSV file to this repository and you can find it listed above.**

The values from the Standard Area Measurements and from the Centroids file can be added to our Conflated table of variables using the following SQL:

```SQL
-- Step 1: Add the empty columns to the PVT_Conflated table
ALTER TABLE `_PROJECT_._DATASET_.PVT_Conflated` 
    ADD COLUMN IF NOT EXISTS LandAreaHect FLOAT64,
    ADD COLUMN IF NOT EXISTS LA22 STRING,
    ADD COLUMN IF NOT EXISTS centroid GEOGRAPHY;

-- Step 2: Update the column values in PVT_Conflated table
UPDATE `_PROJECT_._DATASET_.PVT_Conflated` A
SET A.LandAreaHect = B.Land_Count__Area_in_Hectares_, 
    A.LA22 = B.LTLA22NM
FROM `_PROJECT_._DATASET_.OA21_AREAS` B
WHERE A.Output_Areas = B.OA21CD;

UPDATE `_PROJECT_._DATASET_.PVT_Conflated` A
SET A.centroid = B.centroid
FROM `_PROJECT_._DATASET_.OA21_CENTROIDS` B
WHERE A.Output_Areas = B.OA21CD;
```



## Spatial Aggregation - ST_DWITHIN
The spatial join takes the table of stores and the table of census output area variables and performance a distance-based summary. For this demo, a single distance has been used (10KM): in a more detailed analysis, it would be worthwhile repeaitng the queries with a multiple of distances. This is where BigQuery's spatial functions come into their own - in this case the `ST_DWITHIN` aggregation function is used to identify all the output area centroids within the given distance (10000m in this case) of each of the locations specified by the centroids in the store table.

```SQL
SELECT s.StoreID as Store,
    COUNT(p.Output_Areas) as k10_OAs
    ,SUM(p.TS001Code_1 + p.TS001Code_2) as K10Totalpop
    ,SUM(p.TS001Code_2) / SUM(p.TS001Code_1 + p.TS001Code_2) as K10PercComm
    ,SUM(p.Age__Total) / SUM(LandAreaHect) as K10NumPerHect
    ,SUM(p.Age__Aged_4_years_and_under) / SUM(p.Age__Total) as K10Perc0_4
    ,SUM(p.Age__Aged_5_to_9_years) + SUM(p.Age__Aged_10_to_14_years) / SUM(p.Age__Total) as K10Percc5_14
    ,SUM(p.Age__Aged_25_to_29_years) + SUM(p.Age__Aged_30_to_34_years) + SUM(p.Age__Aged_35_to_39_years) + SUM(p.Age__Aged_40_to_44_years) / SUM(p.Age__Total) as K10Percc25_44
    ,SUM(p.Age__Aged_45_to_49_years) + SUM(p.Age__Aged_50_to_54_years)+ SUM(p.Age__Aged_55_to_59_years) + SUM(p.Age__Aged_60_to_64_years) / SUM(p.Age__Total) as K10Percc45_64
    ,SUM(p.Age__Aged_65_to_69_years) + SUM(p.Age__Aged_70_to_74_years)+ SUM(p.Age__Aged_75_to_79_years) + SUM(p.Age__Aged_80_to_84_years) / SUM(p.Age__Total) as K10Percc65_84
    ,SUM(p.Age__Aged_85_years_and_over) / SUM(p.Age__Total) as K10PercOver85
    ,SUM(p.TS044Code_1 + p.TS044Code_2) as K10L1to6Occ
    ,(SUM(p.TS044Code_1 + p.TS044Code_2) / SUM(p.TS001Code_1 + p.TS001Code_2))as K101to6prop

FROM  `_PROJECT_._DATASET_.stores` s, `_PROJECT_._DATASET_.PVT_Conflated` p     
    WHERE ST_DWITHIN(p.centroid, s.geom, 10000)
    GROUP BY Store

ORDER BY K10Totalpop DESC;
```

The remainder of the aggregated variables in this table are styled on the variables in the original Output Area Classification research paper _TO-DO: write out description of the variables_

After completing this aggregation, we have a table featuring each store that we are interested in with a selection of the input variables summarised for each. Save the results of this query as a new table in BigQuery, as it will form the baiss for Phase 3 - the Clustering.

**IMPORTANT - for the scripts in the Phase 3 to work 'out of the box' save the results of this query as a new table in your dataset, giving it the name `K10Raw` (10 Kilometre, Raw Totals)**
