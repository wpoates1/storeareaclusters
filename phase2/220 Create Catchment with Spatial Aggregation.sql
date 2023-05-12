-- SPATIAL AGGREGATION QUERY ACROSS THE PIVOTED CENSUS TABLES 
SELECT s.StoreID as Store,
    COUNT(p.Output_Areas) as k10_OAs
    ,SUM(p.TS001Code_1 + p.TS001Code_2) as K10Totalpop
    ,SUM(p.TS001Code_2) / SUM(p.TS001Code_1 + p.TS001Code_2) as K10PercComm
    ,SUM(p.Age__Total) / SUM(LandAreaHect) as K10NumPerHect
    ,SUM(p.Age__Aged_4_years_and_under) / SUM(p.Age__Total) as K10Perc0_4
    ,SUM(p.Age__Aged_5_to_9_years) + SUM(p.Age__Aged_10_to_14_years) / SUM(p.Age__Total) as K10Percc5_14
    ,SUM(p.Age__Aged_25_to_29_years) + SUM(p.Age__Aged_30_to_34_years) + SUM(p.Age__Aged_35_to_39_years) + SUM(p.Age__Aged_40_to_44_years) / SUM(p.Age__Total) as K10Percc25_44
    ,SUM(p.Age__Aged_45_to_49_years) + SUM(p.Age__Aged_50_to_54_years)+ SUM(p.Age__Aged_55_to_59_years) + SUM(p.Age__Aged_60_to_64_years) / SUM(p.Age__Total) as K10Percc45_64
    ,SUM(p.Age__Aged_65_to_69_years) + SUM(p.Age__Aged_70_to_74_years)+ SUM(p.Age__Aged_75_to_79_years) + SUM(p.Age__Aged_80_to_84_years) / SUM(p.Age__Total) as K10Percc65_84
    ,SUM(p.Age__Aged_85_years_and_over) / SUM(p.Age__Total) as K10PercOver85
    ,SUM(p.TS044Code_1 + p.TS044Code_2) as K10L1to6Occ
    ,(SUM(p.TS044Code_1 + p.TS044Code_2) / SUM(p.TS001Code_1 + p.TS001Code_2))as K101to6prop

-- THE SPATIAL SELECT - DISTANCE OF 10000M IS HARD-CODED IN HERE
FROM  `_PROJECT_._DATASET_.stores` s, `_PROJECT_._DATASET_.PVT_Conflated` p     
    WHERE ST_DWITHIN(p.centroid, s.geom, 10000)
    GROUP BY Store

ORDER BY K10Totalpop DESC;
