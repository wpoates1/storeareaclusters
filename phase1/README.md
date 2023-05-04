# Phase 2 - Preparing Data Inputs

## Stores Data
In this example, we are starting with a prepared list of stores, giving the location of 160 outlets of a UK retailer. The list has been truncated to include only England and Wales, reflecting the coverage of the ONS census data. Including data for Scotland and Northern Ireland is an obvious extension task. In this instance, the process for preparing this list was:
- web-scraping the addresses of the stores. I used Microsoft PowerAutomate for this, but numerous alternatives are available
- a bit of data tidying up - the scraper output had mis-aligned columns and other annoying issues. Again, sticking with the use of desktop tools in a corporate environment, I used PowerQuery in Excel for a lot of the work. This yielded a list of the stores, with their postal addresses.
-  the final step is geocoding the addresses to apply a latitude/longitude co-ordinates. There are numerous approaches to this, including the official National Statitistics Postcode Lookup (NSPL) dataset. A simpler approach however is to use the marvelous [Doogal](https://www.doogal.co.uk) website of Chris Bell, specifically the [Batch Geocoder](https://www.doogal.co.uk/BatchGeocoding). This fantastically helpful tool gives brilliant set of results for our purposes here. Thanks Chris!

This process yielded a CSV file with nicely formatted addresses, co-ordinates for the postcodes and also a few other additional geography features that may come in handy.


## Census Data - Demographic Data Part 1
Working with the Census data is broadly a straightforward process. There are however a couple of minor frustrations for those of us who are seeking to work directly with a broad range of data, as ONS' web-site is targetted more towrads topic-specific reports and analysis. Finding datasets to download requires navigating through a heirarchy of pages and reports and then working through a wizard-style helper tool.

The data 

_Extension Task:_ extend the coverage to include the census data.
