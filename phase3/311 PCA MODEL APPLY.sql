SELECT * FROM ML.PREDICT(MODEL `gdms-demo-20230201.census2021.PCA_10Clusters_OAandPop_KPP`, 
  (SELECT * FROM `gdms-demo-20230201.census2021.K10Raw`))
