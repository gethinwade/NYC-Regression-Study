import requests
import pandas as pd
import pgeocode
import numpy as np

OPEN_DATA_KEY = ''
CENSUS_KEY = ''

# ----- RAT INSPECTION PORTAL (RIP) DATA ----- #
dataset_id = "p937-wjvj"
url = f"https://data.cityofnewyork.us/resource/{dataset_id}.json"

headers = {"app_token": OPEN_DATA_KEY}
params = {
    '$limit': 1000000,
    '$where': "inspection_date >= '2023-01-01T00:00:00' AND inspection_date < '2024-01-01T00:00:00' AND inspection_type='Initial'"
}

response = requests.get(url, headers=headers, params=params)
rat_df = pd.DataFrame(response.json())


# ----- POPULATION DATA ----- #
url = "https://api.census.gov/data/2022/acs/acs5"

params = {
    'get': 'NAME,B01003_001E',
    'for': 'zip code tabulation area:*',
    'key': CENSUS_KEY
}

response = requests.get(url, params=params, timeout=30)
data = response.json()
df = pd.DataFrame(data[1:], columns=data[0])
df.columns = ['name', 'population', 'ZIP']

# Filtering for NYC zip codes
pop_df = df[df['ZIP'].str.startswith(('100', '101', '102', '103', '104', 
    '111', '112', '113', '114', '116'))].reset_index(drop=True)


# ----- OTHER COVARIATES ----- #
headers = {"app_token": OPEN_DATA_KEY}
params = {'$limit': 50000}

def fetch_data(dataset_id):
    url = f"https://data.cityofnewyork.us/resource/{dataset_id}.json"
    response = requests.get(url, headers=headers, params=params)
    df = pd.DataFrame(response.json())
    return df

garage_df = fetch_data('xw3j-2yxf')
food_scrap_df = fetch_data('if26-z6xq')
litter_basket_df = fetch_data('8znf-7b2c')


# ----- DATA WRANGLING ----- #

# Creating the combined dataframe
regression_df = rat_df.groupby('zip_code').size().reset_index(name='inspections')

regression_df = regression_df.merge(
    pop_df[['ZIP', 'population']],  # Set ZIP as index, adds only the population column
    left_on='zip_code',
    right_on='ZIP',  # Merge on the index instead of a column
    how='inner' # Keep only rows with values for both inspections and population
).drop(columns=['ZIP'])

# Zip codes that have a DSNY garage
zips_with_garages = set(garage_df['zip'].unique())

# Adding a dummy variable: 1 if the zip code has a garage, 0 if not
regression_df['has_garage'] = regression_df['zip_code'].isin(zips_with_garages).astype(int)

# Initialize geocoder and get postal data
geocoder = pgeocode.Nominatim('us')
postal_df = geocoder._data_frame

# Convert to numeric
food_scrap_df['latitude'] = pd.to_numeric(food_scrap_df['latitude'], errors='coerce')
food_scrap_df['longitude'] = pd.to_numeric(food_scrap_df['longitude'], errors='coerce')

# Function to find nearest ZIP
def get_zip(lat, lon):
    if pd.isna(lat) or pd.isna(lon):
        return None

    distances = np.sqrt(
        (postal_df['latitude'] - lat)**2 + 
        (postal_df['longitude'] - lon)**2
    )
    nearest_idx = distances.idxmin()
    return str(int(postal_df.loc[nearest_idx, 'postal_code']))

# Apply to DataFrame
food_scrap_df['zip_code'] = food_scrap_df.apply(lambda row: get_zip(row['latitude'], row['longitude']), axis=1)

# Zip codes that have a DSNY garage
zips_with_dropoffs = set(food_scrap_df['zip_code'].unique())

# Adding a dummy variable: 1 if the zip code has a dropoff, 0 if not
regression_df['has_dropoff'] = regression_df['zip_code'].isin(zips_with_dropoffs).astype(int)


print(regression_df.head())
print(len(regression_df))
regression_df.to_csv('project_data.csv', index=False)
