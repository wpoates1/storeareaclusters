-- CHANGE THE PROJECT AND DATASET VALUES BELOW AND IN THE JOIN STATEMENTS BELOW
CREATE OR REPLACE TABLE _PROJECT_._DATASET_.PVT2_Conflated AS
SELECT
  T1.geography_code,
  T1.* EXCEPT(date, geography, geography_code),
  T2.* EXCEPT(Output_Areas),
  T3.* EXCEPT(Output_Areas)
FROM
  _DATASET_.TS055_Bedrooms AS T1
JOIN
  _DATASET_.PVT_TS044_Accommodation AS T2
ON
  T1.geography_code = T2.Output_Areas
JOIN
  _DATASET_.PVT_TS062_NSSEC AS T3
ON
  T1.geography_code = T3.Output_Areas;
