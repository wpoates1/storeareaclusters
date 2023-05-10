# Clustering

This phase takes the demographic aggregations from Phase 2, uses the K Means clustering unspervised learning algorithm to identify groups of stores with similar demographic characteristics. The clustering approach harnesses BigQuery's AutoML functions. To inspect the outcome of the clustering process a second AutoML function is applied - Principal Component Analysis (PCA) - and then joined with the Cluster results to allow a graphical plot to be generated.

Please note that the explanations below aren't presented as a lesson in statistics and readers are urged to do their own reading to ensure that they have a full understanding of the approaches being applied.


## KMeans Clustering
The SQL to create the model is below. This operates over the table created in Phase2 - `K10Raw` in this instance. The model is created with a name that relfects the particular choice of parameters and starting conditions. The choices in the query are the result of experimentation and evaluation using the Davies–Bouldin index, which is automatically reported by BigQuery during construction of the model and represents the ratio of the intra-cluster spread to the inter-cluster distance. A lower number is indicative of data that are tightly grouped around a series of specific focal points that are themselves quite widely dispersed. A series of test runs were used to explore the impact of the different parameter settings with the choices in the SQL below representing the optimal set.

- `NUM_CLUSTERS`: this is actually an optional parameter and when left unspecified BigQuery will find the optimum number of clusters. In the case of this dataset, this resulted in only 2 clusters - not very useful for this application. Tests runs with specifying 5 and 10 clusters yielded better scores for the Davies-Bouldin index with the larger number of clusters. This may be an artefact of the way in which that index is created - some literature suggest that the index should be normalized by the number of clusters. 
- `STANDARDIZE_FEATURES`: this was found to have only a minimal impact on the index score, but has been included in the results largely as the underlying methodology paper from ONS also uses a standardisation on the cluster results. Note that ONS paper uses a variety of standardisation methods which are of greater sophistication, which could be incorporated into the spatial aglommeration step in the previous phase
- `KMEANS_INIT_METHOD`: the ues of the `KMEANS++` initialisation method is well proven to be at least as good as, and general significantly better than, the use of random seed points for the initial clusters. That was bourne out in this instance, with the Davies-Bouldin index being improved substantially.

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

To apply the model created by this step to the list of stores, run the following SQL, again replacing the Project and Dataset and taking care with the names of the model and the `K10Raw` table name.

```SQL
SELECT * FROM ML.PREDICT(MODEL `_PROJECT_._DATASET_.KMean10_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))   
 ```
 
 ## PCA - Dimensionality Reduction
 The clusters created using KMeans are clustered in a 26-dimesion space - each dimension being one of the variables examined by the algorithm. Plotting and visualsing a 26-dimension space is clearly not possible, so a process of Dimensionality Reduction needs to be applied, to get us down to 2-dimensions that we can plot on an X and a Y axis. This is where the PCA model comes into play. This algorithm identifies which features have the most significant impact on the distribution of the stores and in effect combines these dimensions down into the number required here (i.e. 2).
 
 The SQL used to create the PCA model using BigQuery AutoML is below. Replace the names as required. As explained above, the parameter specified here ensures that we end up with the 2 dimensions needed to allow the plot to be developed:
 
 ```SQL
 CREATE OR REPLACE MODEL _DATASET_.PCA_10Clusters_OAandPop_KPP
OPTIONS(model_type='PCA', NUM_PRINCIPAL_COMPONENTS=2) AS
SELECT * EXCEPT (Store) FROM `_PROJECT_._DATASET_.K10Raw`
```

Applying the model to the dataset with:

```SQL
SELECT * FROM ML.PREDICT(MODEL `gdms-demo-20230201.census2021.PCA_10Clusters_OAandPop_KPP`, 
  (SELECT * FROM `gdms-demo-20230201.census2021.K10Raw`))
```

## Visualising the Cluster Results
To visualise the clusters produced by the model in 2 Dimensions, the following query applies both the KMeans model and the PCA Model and pulls the results together. Save the results as a table in the dataset. The table will specify the store, the cluster ID and an X and a Y value that can be used for plotting on a scatter graph.

```SQL
-- USES THE PCA AND KMEANS MODELS TO CREATE THE INPUTS FOR A 2D CLUSTER MAP

WITH kmean_prediction AS (
  SELECT * EXCEPT (nearest_centroids_distance) 
  FROM ML.PREDICT(MODEL `_PROJECT_._DATASET_.KMean10_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))
),
pca_prediction AS (
  SELECT * 
  FROM ML.PREDICT(MODEL `_PROJECT_._DATSET_.PCA_10Clusters_OAandPop_KPP`, 
    (SELECT * FROM `_PROJECT_._DATASET_.K10Raw`))
)

SELECT p.Store, k.CENTROID_ID, p.principal_component_1 as PCA_X, p.principal_component_2 as PCA_Y, K.* EXCEPT (CENTROID_ID, Store)
FROM kmean_prediction k
JOIN pca_prediction p
ON k.Store = p.Store
ORDER BY 2, 1
```

From this point, the table of results can be visualised using a tool of your choice! Export the table to CSV and import into Excel, for example. Another option is to use Looker Studio natively in Google Cloud, using the 'Explore with Looker Studio' option in the Export function. You will be able to produce sometihng that looks like this:

![Cluster Map Outomce](https://github.com/wpoates1/storeareaclusters/blob/main/phase3/2D%20cluster%20plot.png)

A top tip to aid the visualisation was to use an optimised colour palatte. Plenty of online guides for good colour palette design, including [this one](https://www.heavy.ai/blog/12-color-palettes-for-telling-better-stories-with-your-data).


