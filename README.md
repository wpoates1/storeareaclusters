# Store Area Clusters
Use GCP BigQuery and 2021 Census data to apply sociodemographic clustering to a store catchment areas.

## Introduction
This is designed as an introduction to Geospatial and basic unsupervised Machine Learning techniques, using newly released data from the UK 2021 Census to analyse the population catchment areas of a retail store locations across England and Wales. It was prepared for a workshop at the Spatial Data Science Conference, London, in May 2023. [Full Presentation](https://github.com/wpoates1/storeareaclusters/blob/main/Demographic%20Catchment%20Area%20Profiles.pdf) from the event. The pages below provide instructions, data sources (as URLs) and SQL code to allow the user to reproduce the findings. No claims are made as to the robustness of the findings and it is intended to demonstrate the capabilities of the tools and as a starting point for further investigations and ongoing skills development. The initial work has been undertaken using BigQuery, and can be accomplished using Google's 'free' Cloud tier. It can easily be re-produced on other platforms, particularly Snowflake, which has many similar properties.

The vast majority of the code is intentionally written entirely in SQL. This choice means that there is no need to install any local software and that the work can be completed entirely within the database environment, and within the free tier of the cloud platform. Some of the SQL is a little tortuous and lengthy - I have tried however to divide the work up into logical phases to make it easier to follow and subsequently extend and modify. I accept that there may be easier and quicker ways of accomplishing the same outcomes in e.g. Python, but I wanted to see how much it's possible to accomplish in a pure SQL approach. The aim for each stage is a single SQL script, using parameters so that it can be used in your own BigQuery environment. One of the obvious extensions to what I've provided is a greater degree of automation. Such automation could easily be used to import further Census data tables, to add more catchment zone distances, to conduct more tests of the clustering approach, or even to chain together the whole process so that it can be conducted for multiple collection of stores.

Finally, for the moment, I have anonymised the stores used in this example. Perhaps you can work out which retailer it is!

## Structure
- **Pre-requisites:** what you need to have to proceed with the work
- **Phase 1:** initialising the stores data and the census data
- **Phase 2:** creating the features for use in the clustering model, including the spatial agglomeration ('feature engineering')
- **Phase 3:** running the KMeans and PCA model. Evaluating the results and visualising the cluster plot
- **Phase 4:** Geographic visualisation

Each phase is a separate GitHub folder, with explanatory text and code for each phase.

## Methodology
The approach followed in this demonstration is based on the the Area Classification method - see the methodology note at https://www.ons.gov.uk/methodology/geography/geographicalproducts/areaclassifications/2011areaclassifications/methodologyandvariables. The variables used to construct the clusters represented a selection of the ones used in that approach.

