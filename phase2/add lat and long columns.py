import pyproj
import pandas as pd

# Define the coordinate reference system for the Ordnance Survey National Grid
osng_crs = pyproj.CRS('EPSG:27700')

# Define the coordinate reference system for latitude and longitude
latlng_crs = pyproj.CRS('EPSG:4326')

# Load your CSV file into a Pandas DataFrame
df = pd.read_csv('Output_Areas_(Dec_2021)_PWC_(Version_2).csv')

# Convert the X and Y columns to latitude and longitude using pyproj
lonlat = pyproj.Transformer.from_crs(osng_crs, latlng_crs, always_xy=True).transform(df['X'].tolist(), df['Y'].tolist())

# Add new columns for latitude and longitude to the DataFrame
dfLat=pd.DataFrame(lonlat[1])
dfLat.columns = ['latitude']

dfLong=pd.DataFrame(lonlat[0])
dfLong.columns = ['longitude']

df=df.join(dfLat)
df=df.join(dfLong)


#df['latitude'] = [x[1] for x in lonlat]
#df['longitude'] = [x[0] for x in lonlat]


# Write the updated DataFrame to a new CSV file
df.to_csv('Output_Areas_2021_PWCv2.csv', index=False)
