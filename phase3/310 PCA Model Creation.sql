CREATE OR REPLACE MODEL _DATASET_.PCA_10Clusters_OAandPop_KPP
OPTIONS(model_type='PCA', NUM_PRINCIPAL_COMPONENTS=2) AS
SELECT * EXCEPT (Store) FROM `_PROJECT_._DATASET_.K10Raw`