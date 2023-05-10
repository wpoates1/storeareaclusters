# Phase 4 - Geographic Visualisation

## Minimal Viable Visualisation
The easiest way of visualising the results is to use Google's GeoDataViz tool. This isn't a particularly sophisticated tool, but suffices to produce a simple overview of the work completed.

Before visualising, the results of the clustering need to be combined with the original store location data and other useful information. The query for this is:


```SQL
-- USES THE PCA AND KMEANS MODELS TO CREATE THE INPUTS FOR A 2D CLUSTER MAP - AS PER PHASE 3 WORK
--  IN THIS CASE, ALSO ADDS THE GEOGRAPHY FIELDS AND SAVES THE RESULTS TO A TABLE
CREATE OR REPLACE TABLE `_PROJECT_._DATASET_.FINAL_STORE_CLUSTERS` AS

WITH 
kmean_prediction AS (
  SELECT * EXCEPT (nearest_centroids_distance) 
  FROM ML.PREDICT(MODEL `_PROJECT_._DATASET_.KMean10_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))
),
pca_prediction AS (
  SELECT * 
  FROM ML.PREDICT(MODEL `_PROJECT_._DATSET_.PCA_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))
),
stores AS (
  SELECT StoreID, StoreName, Latitude, Longitude, Region, geom
  FROM `_PROJECT_._DATASET_.stores`
)

SELECT S.StoreName as Store, p.Store as StoreID, k.CENTROID_ID as Cluster, p.principal_component_1 as PCA_X, p.principal_component_2 as PCA_Y, 
       s.Latitude, s.Longitude, s.geom, s.Region, K.* EXCEPT (CENTROID_ID, Store)
FROM kmean_prediction k
JOIN pca_prediction p
ON k.Store = p.Store
JOIN stores s
ON p.Store = s.StoreID
ORDER BY 3, 1
```

Having created this final output, you can then navigate to that table and select the 'Explore with GeoViz' option in the Export menu. The geography field `geom` should be automatically detected to locate each store. It's then a question of styling the results - a good starting point is to set the `circleRadius` to a fixed size of 10000 (representing the area covered by each store), the `fillOpacity` to 0.5 and then set the `fillColor` to Data-driven, with the 'categorical' function, the Cluster field with domains 1 through to 10 manually added. The following colours (obtained from the colour palette picker used in the previous stage) might be helpful:

```
#b30000
#7c1158
#4421af
#1a53ff
#0d88e6
#00b7c7
#5ad45a
#8be04e
#ebdc78
#fd7f6f
```

You should end up with something like the following results:
