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
