# L4G4_DataDestroyers
DATA201/422 Group Project Group L4G4

## Description:
This project compares New Zealand's short-term (Airbnb) and long-term (rental bond) 
housing markets in Christchurch. Airbnb listings and Tenancy Services rental bond 
data are each matched to Stats NZ Statistical Area 2 (SA2) geographic areas.
Airbnb listings via their latitude/longitude through the Koordinates Query API, 
and rental bond records via their existing `Location Id` so the two datasets 
can be compared and summarised side by side, down to SA2 and ward level.

## Installation:

1. Clone the repository and open `L4G4_DataDestroyers.Rproj` in RStudio.
2. Run `renv::restore()` to install the exact package versions the project was built with (see `renv.lock`).
3. Get a free Koordinates account and API key at (https://koordinates.com) needed for `2_scripts/7_airbnb_parallel_processing.R` (see **Area Code Data** below).
   Paste your key into the `api_key` variable at the top of that script, **or**, preferably, set `KOORDINATES_API_KEY=your_key_here` in a local `.Renviron` file 
   (already gitignored, never commit the API key) and read it in the script with `Sys.getenv("KOORDINATES_API_KEY")`.

## Project Structure:

```
1_data/          Raw and reference data (Airbnb listings, tenancy bond data, Stats NZ area tables)
2_scripts/       Numbered R scripts, run in order, see Pipeline below
3_output/        Cleaned, joined and summarised data produced by the scripts
4_documentation/ Cleaning logs, summaries and this README
z_Bin/           Old/superseded scripts kept for reference
```

## Pipeline:

Run the scripts in `2_scripts/` in numeric order:

| # | Script | What it does |
|---|---|---|
| 1 | `1_ airbnb_preprocessing.R` | Preprocesses the raw NZ-wide Airbnb listings |
| 2 | `2_tenancy_preprocessing.R` | Preprocesses the raw tenancy bond data |
| 3 | `3_airbnb_datasummary.R` | Produces summary statistics for the Airbnb data |
| 4 | `4_airbnb_chch_visualisation.R` | Visualisations of Christchurch Airbnb listings |
| 5 | `5_airbnb_cleaning.R` | Cleans the Christchurch Airbnb data |
| 6 | `6_tenancy_cleaning.R` | Cleans the Christchurch tenancy data |
| 7 | `7_airbnb_parallel_processing.R` | Looks up each Airbnb listing's Stats NZ SA2 area code via the Koordinates API |
| 8 | `8_full_rental_summarise_location.R` | Summarises Airbnb and tenancy data by SA2 and joins them together |
| 9 | `9_airbnb_medianprice_chch_central.R` | Median Airbnb price for central Christchurch |
| 10 | `10_full_rental_price_difference.R` | Finds the location with the largest Airbnb vs long-term rent price gap |
| 11 | `11_full_rental_compare_properties.R` | Compares Airbnb vs tenancy property counts by SA2 |
| 12 | `12_full_rental_grouping.R` | Groups the SA2 level summary up to ward level |

Shared helper functions used by the scripts above live in `2_scripts/0_tools/`.

## Airbnb Dataset:

| Column Name | Data Type | Description |
|---|---|---|
| `id` | Integer | Primary key / Unique identifier for the listing |
| `name` | Text | Name or title of the Airbnb listing |
| `host_id` | Integer | Unique identifier for the property host |
| `host_name` | Text | First name of the host |
| `neighbourhood_group` | Text | Region (e.g., Auckland, Wellington, Canterbury) |
| `neighbourhood` | Text | Local area, suburb, or ward |
| `latitude` | Numeric | Latitude coordinates (WGS84 format) |
| `longitude` | Numeric | Longitude coordinates (WGS84 format) |
| `room_type` | Text | Property classification: `Entire place`, `Private room`, or `Shared room` |
| `price` | Currency | Nightly rate listed in New Zealand Dollars (NZD) |
| `minimum_nights` | Integer | Minimum required length of stay in nights |
| `number_of_reviews` | Integer | Total reviews received by the listing |
| `last_review` | Date | Date of the most recent review (`YYYY-MM-DD`) |
| `reviews_per_month` | Numeric | Average number of reviews per month over the lifetime of the listing |
| `calculated_host_listings_count` | Integer | Total number of listings owned by the host at the time of the scrape |
| `availability_365` | Integer | Number of available days in the upcoming 365 days |
| `number_of_reviews_ltm` | Integer | Number of reviews received in the last 12 months |
| `license` | Text | License, permit, or registration number (if applicable under local council regulations) |


### Source and Licence:
Sourced from Inside Airbnb.

**Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0).

**Attribution:** Inside Airbnb / Murray Cox.

https://insideairbnb.com/get-the-data/

### Note:
#### Room Type Categories

The room_type column may contain the following values:

- Entire home/apt: Guests have access to the entire property.
- Private room: Guests have a private bedroom but may share other spaces.
- Shared room: Guests share the sleeping area with other people.

#### Availability_365

The availability_365 value should not be interpreted directly as the number of vacant days.

A listing may be unavailable because:

- it has already been booked;
- the host has blocked the date;
- the listing is temporarily inactive; or
- booking restrictions have been applied.

#### Reviews per Month

If the number of days between the scrape date and the first review is 30 or fewer:

    reviews_per_month = number_of_reviews

Otherwise:

    reviews_per_month =
        number_of_reviews /
        ((scrape_date - first_review + 1) / (365 / 12))


___

## Bond Dataset:

| Column Name | Data Type | Description |
|---|---|---|
| `TimeFrame` | Date | Quarter the rental data relates to |
| `Location Id` | Integer | Unique identifier for the location |
| `Dwelling Type` | Text | Type of dwelling |
| `Number Of Beds` | Integer | Number of bedrooms in the dwelling |
| `Total Bonds` | Integer | Total number of rental bonds |
| `Active Bonds` | Integer | Number of active rental bonds |
| `Closed Bonds` | Integer | Number of closed rental bonds |
| `Median Rent` | Currency | Median weekly rent in New Zealand Dollars (NZD) |
| `Geometric Mean Rent` | Currency | Average weekly rent calculated using the geometric mean |
| `Upper Quartile Rent` | Currency | Weekly rent at the upper quartile |
| `Lower Quartile Rent` | Currency | Weekly rent at the lower quartile |
| `Log Std Dev Weekly Rent` | Numeric | Measure of variation in weekly rent |

### Bond Data Source and Licence:

Sourced from Tenancy Services – Ministry of Business, Innovation and Employment (MBIE).

**Licence:** Creative Commons Attribution 3.0 New Zealand (CC BY 3.0 NZ).

**Attribution:** Ministry of Business, Innovation and Employment (MBIE).

Dataset: Detailed Quarterly Report, Q1 2020 – Q3 2026.

https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/

[Tenancy Services – Rental Bond Data](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/)
('The Ministry of Business, Innovation and Employment') 


### Bond Data Description:

The dataset contains quarterly rental bond information for different locations, dwelling types and numbers of bedrooms across New Zealand. The data includes rental bond counts and weekly rental prices.

## Area Code Data (Koordinates)

__Dataset:__ Statistical Area 2 2026  
__Description:__ Definitive version of Statistical Area 2 (SA2) boundaries as at 1 January 2026, as defined by Stats NZ. This version contains 2,311 SA2s, excluding the 16 SA2s with empty or null geometries (non-digitised).  
__Layer ID:__ 123515  
__Link:__ https://koordinates.com/from/datafinder.stats.govt.nz/layer/123515-statistical-area-2-2026/  
__Source / Data Owner:__ Stats NZ – Tatauranga Aotearoa  
__Created by:__ Geospatial and Data Acquisition Team, Stats NZ  
__Licence:__ Creative Commons Attribution 4.0 International (CC BY 4.0)  
__Attribution:__ Stats NZ – Tatauranga Aotearoa
__Accessed via:__ Stats NZ Geographic Data Service / Koordinates

 
## Ward / Geographic Areas Data

__Dataset:__ Geographic Areas Table 2023 (meshblock-level concordance)  
__Description:__ Stats NZ table mapping every 2023 meshblock to its SA1, SA2, ward, territorial authority and other geographic classifications. Used in `12_full_rental_grouping.R` to attach a ward to each SA2 area code, filtered to `TA2023_name == "Christchurch City"`.  
__Source / Data Owner:__ Stats NZ – Tatauranga Aotearoa  
__Licence:__ Creative Commons Attribution 4.0 International (CC BY 4.0)  
__Attribution:__ Stats NZ – Tatauranga Aotearoa  
__Accessed via:__ Stats NZ Geographic Data Service / Datafinder  
__File:__ `1_data/geographic-areas-table-2023.csv`

__Notes:__
- SA2 codes matched exactly between the 2026 SA2 boundaries (used for the Airbnb area codes) and this 2023-vintage table, for all 179 Christchurch SA2 areas.
- SA2 boundaries don't always sit inside a single ward: 44 of Christchurch's 179 SA2 areas span more than one ward. Each is assigned to whichever ward contains the most meshblocks of that SA2 (the majority ward) -- see `3_output/sa2_to_ward_lookup.csv` for the full crosswalk, including how many wards each SA2 touched.
- One SA2 (`363800`) is coded "Area Outside Territorial Authority" in the Stats NZ table and has no ward assigned.
