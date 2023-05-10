# Clustering

This phase takes the demographic aggregations from Phase 2, uses the K Means clustering unspervised learning algorithm to identify groups of stores with similar demographic characteristics. The clustering approach harnesses BigQuery's AutoML functions. To inspect the outcome of the clustering process a second AutoML function is applied - Principal Component Analysis (PCA) - and then joined with the Cluster results to allow a graphical plot to be generated.


## KMeans Clustering
The SQL to create the model is below. This operates over the table created in Phase2 - `K10Raw` in this instance. The model is created with a name that relfects the particular choice of parameters and starting conditions. The choices in the query are the result of experimentation and evaluation using the Davies–Bouldin index.

```SQL
-- CREATES A NEW KMEANS MODEL
CREATE OR REPLACE MODEL _DATASET_.KMean10_10Clusters_OAandPop_Std_KPP
  OPTIONS(model_type='kmeans', 
          NUM_CLUSTERS=10,
          STANDARDIZE_FEATURES = TRUE,
          KMEANS_INIT_METHOD = 'KMEANS++') AS
SELECT * EXCEPT (Store) FROM `_PROJECT_._DATASET_.K10Raw`
```

See these links for further details of the model operation
- [BigQuery KMeans function documentation](https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-create-kmeans) - pretty clear explanation of the parameters and their importance
- [End to End Journey for AutoML Models](https://cloud.google.com/bigquery/docs/reference/standard-sql/bigqueryml-syntax-e2e-journey) - a good reference for the steps involved in creating and applying Clustering and all AutoML models;
- [KMeans Tutorial](https://cloud.google.com/bigquery/docs/kmeans-tutorial) - lots of quite complex SQL, but explains the process
