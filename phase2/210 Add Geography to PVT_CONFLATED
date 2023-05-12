-- Step 1: Add the empty columns to the PVT_Conflated table
ALTER TABLE `_PROJECT_._DATASET_.PVT_Conflated` 
    ADD COLUMN IF NOT EXISTS LandAreaHect FLOAT64,
    ADD COLUMN IF NOT EXISTS LA22 STRING,
    ADD COLUMN IF NOT EXISTS centroid GEOGRAPHY;

-- Step 2: Update the column values in PVT_Conflated table
UPDATE `gdms-demo-20230201.census2021.PVT_Conflated` A
SET A.LandAreaHect = B.Land_Count__Area_in_Hectares_, 
    A.LA22 = B.LTLA22NM
FROM `_PROJECT_._DATASET_.OA_AREAS` B
WHERE A.Output_Areas = B.OA21CD;

UPDATE `gdms-demo-20230201.census2021.PVT_Conflated` A
SET A.centroid = B.centroid
FROM `_PROJECT_._DATASET_.OA21_CENTROIDS` B
WHERE A.Output_Areas = B.OA21CD;
