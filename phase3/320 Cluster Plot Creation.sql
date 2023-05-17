-- USES THE PCA AND KMEANS MODELS TO CREATE THE INPUTS FOR A 2D CLUSTER MAP

WITH kmean_prediction AS (
  SELECT * EXCEPT (nearest_centroids_distance) 
  FROM ML.PREDICT(MODEL `_PROJECT_._DATASET_.KMean10_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))
),
pca_prediction AS (
  SELECT * 
  FROM ML.PREDICT(MODEL `_PROJECT_._DATASET_.PCA_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))
)

SELECT p.Store, k.CENTROID_ID, p.principal_component_1 as PCA_X, p.principal_component_2 as PCA_Y, K.* EXCEPT (CENTROID_ID, Store)
FROM kmean_prediction k
JOIN pca_prediction p
ON k.Store = p.Store
ORDER BY 2, 1
