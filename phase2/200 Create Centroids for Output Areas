-- ADDS CENTROIDS COLUMN AND CREATES THE SPATIAL POINT DATA
--  OPERATES OVER A TABLE LOADED FROM ONS DATA AT 
--   https://geoportal.statistics.gov.uk/datasets/ons::output-areas-dec-2021-pwc-version-2/about

ALTER TABLE `_PROJECT_._DATASET_.OA21_CENTROIDS` 
    ADD COLUMN IF NOT EXISTS centroid GEOGRAPHY;

UPDATE `_PROJECT_._DATASET_.OA21_CENTROIDS`
    SET centroid = ST_GEOGPOINT(longitude,latitude) WHERE true;
