-- APPLIES THE KMEANS MODEL CREATED IN THE PREVIOUS STEP 
SELECT * FROM ML.PREDICT(MODEL `_PROJECT_._DATASET_.KMean10_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))   