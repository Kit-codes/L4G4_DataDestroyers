# L4G4_DataDestroyers

DATA201/422 Group Project, Group L4G4

## Description

This project compares New Zealand's short-term (Airbnb) and long-term (rental bond) housing markets in Christchurch.

Airbnb listings and Tenancy Services rental bond data are each matched to Stats NZ Statistical Area 2 (SA2) areas:

- Airbnb listings are matched through their latitude/longitude using the Koordinates Query API.
- Rental bond records are matched through their existing `Location Id`.

The two datasets can then be compared and summarised side by side, down to SA2 and ward level.

## Getting started

### 1. Set up R

1. Clone the repository and open `L4G4_DataDestroyers.Rproj` in RStudio. Opening the project (rather than just the folder) makes sure file paths resolve from the project root.
2. In the R console, run `renv::restore()` to install the exact package versions the project was built with (see `renv.lock`).

### 2. Get a Koordinates API key

The pipeline looks up each Airbnb listing's SA2 area through the Koordinates API.

1. Create a free account and API key at <https://koordinates.com>.
2. Copy `.Renviron.example` to a new file called `.Renviron` in the project root.
3. Paste your key after `KOORDINATES_API_KEY=` and save.
4. Restart R, because R only reads `.Renviron` at startup.

The key is only used by `02_scripts/05_airbnb_parallel_processing.R`, and only for listing locations that are not already in the cache (`03_output/area_code_lookup.csv`). `03_output/` is not stored in the repository, so **the first run on a fresh clone always needs the key**. Later runs only query new locations.

### 3. Run the pipeline

From R / RStudio:

```r
source("pipeline.R")
run_pipeline()              # check folders and config.yaml, run every script, render the report
run_pipeline(from = 5)      # resume from script 05 onwards (then render the report)
run_pipeline(report = FALSE)  # skip the report
render_report()             # only re-render the report
check_project_structure()   # only check folders, scripts and input files
```

From a terminal in the project root:

```
Rscript pipeline.R              # run every script, then render the report
Rscript pipeline.R --check      # only check folders and config.yaml
Rscript pipeline.R --from 5     # resume from script 05 (then render the report)
Rscript pipeline.R --no-report  # run the scripts but skip the report
Rscript pipeline.R --report     # only re-render the report
make                            # only re-run steps whose inputs have changed (including the report)
```

Notes:

- The last step renders the report (see Results report) to `04_documentation/01_analysis_results/Results.pdf`, so its plots and numbers always match the latest data. This needs Quarto (bundled with RStudio, or from <https://quarto.org>). If Quarto isn't found the data steps still finish and you get a warning.
- The check step creates any missing output folders and stops with a clear message if a script, input file or `config.yaml` setting is wrong.
- `make` re-runs only what is out of date, for example after adding a new month of Airbnb data or editing `config.yaml`. Do not use `make -j`, because the steps must run one after another. `make clean` removes generated files but keeps the API lookup cache; `make clean-all` removes that too.

### Adding new Airbnb months

Drop new `listings_YYYY_MM.csv.gz` files into `01_data/01_airbnb_rawdata/` and run the pipeline again. The month range, tenancy date window, latest-snapshot filters and API lookups all follow from the files in that folder. The file names must match this pattern exactly.

## Configuration

Analysis settings live in `config.yaml`. Scripts read them from there, so edit that file rather than the scripts.

| Setting | Meaning |
|---|---|
| `area` | Council area to analyse (default `Christchurch City`). Must match the Airbnb `neighbourhood_group` and the Stats NZ `TA2023_name` |
| `koordinates_layer_id` | Koordinates layer used to find each listing's SA2 (`123515`, Statistical Area 2 2026) |
| `dwelling_type`, `number_of_beds` | Tenancy rows to keep: the `ALL` summary rows covering all dwelling types / bedroom counts |
| `central_sa2_name` | SA2 whose median Airbnb price is reported by script 10 |
| `collection_date` | Date the latest Airbnb snapshot was collected (`YYYY-MM-DD`, in quotes). `null` uses the last day of the latest month, because the listings files don't contain it |

## Project structure

```
01_data/            Raw and reference data (Airbnb listings, tenancy bond data, Stats NZ area tables)
02_scripts/         Numbered R scripts (run in order) and shared helpers in 00_tools/
03_output/          Generated: cleaned, joined and summarised data, plus plots in 00_plots/
04_documentation/   Cleaning logs, data summary, design principles and the Results report
config.yaml         Analysis settings (see Configuration)
pipeline.R          Runs the whole project (see Run the pipeline)
Makefile            Runs only the steps that are out of date
renv.lock           Package versions used by the project
```

`03_output/` is generated by the pipeline and is not stored in the repository.

## Pipeline

The scripts in `02_scripts/` are run in numeric order by `pipeline.R`. Shared helper functions (`config.R`, `data_summary.R`, `topPercent.R`) live in `02_scripts/00_tools/`.

| # | Script | What it does |
|---|---|---|
| 01 | `01_airbnb_preprocessing.R` | Combines the raw monthly Airbnb listings and selects the configured area |
| 02 | `02_tenancy_preprocessing.R` | Filters the raw tenancy bond data to the Airbnb date range and Christchurch SA2 areas |
| 03 | `03_airbnb_cleaning.R` | Cleans the Christchurch Airbnb data and writes a cleaning log |
| 04 | `04_tenancy_cleaning.R` | Cleans the Christchurch tenancy data and writes a cleaning log |
| 05 | `05_airbnb_parallel_processing.R` | Looks up each listing's Stats NZ SA2 area code via the Koordinates API (cached) |
| 06 | `06_full_rental_summarise_location.R` | Summarises Airbnb and tenancy data by SA2 and joins them |
| 07 | `07_full_rental_summarise_ward.R` | Groups the SA2-level summary up to ward level |
| 08 | `08_airbnb_datasummary.R` | Produces summary statistics for the Airbnb data (`04_documentation/chch_summary.md`) |
| 09 | `09_airbnb_chch_visualisation.R` | Plots Airbnb price distributions and days since last review |
| 10 | `10_airbnb_medianprice_chch_central.R` | Median Airbnb price for the central SA2 |
| 11 | `11_full_rental_price_difference.R` | Finds the location with the largest Airbnb vs long-term rent price gap |
| 12 | `12_full_rental_compare_properties.R` | Compares Airbnb listing counts with active rental bonds by SA2 |
| 13 | `13_full_rental_pricevisualisation.R` | Plots Airbnb vs rental prices and counts by SA2 and ward |

Plots are saved to `03_output/00_plots/`, cleaning logs and the data summary to `04_documentation/`, and everything else to `03_output/`.

## Results report

`04_documentation/01_analysis_results/Results.qmd` is a Quarto report that is rendered to `Results.pdf` automatically at the end of `Rscript pipeline.R` and `make`. It builds its plots by running scripts 09 and 13 and reads the tables in `03_output/`. The descriptions under each graph calculate their numbers from the same data, so they update when new Airbnb months are added. To render it on its own, run the pipeline first, then use `Rscript pipeline.R --report` or the Render button in RStudio.

## Airbnb dataset

Raw files: `01_data/01_airbnb_rawdata/listings_YYYY_MM.csv.gz`

| Column Name | Data Type | Description |
|---|---|---|
| `id` | Integer | Primary key / unique identifier for the listing |
| `name` | Text | Name or title of the Airbnb listing |
| `host_id` | Integer | Unique identifier for the property host |
| `host_name` | Text | First name of the host |
| `neighbourhood_group` | Text | Region (e.g., Auckland, Wellington, Canterbury) |
| `neighbourhood` | Text | Local area, suburb, or ward |
| `latitude` | Numeric | Latitude coordinates (WGS84 format) |
| `longitude` | Numeric | Longitude coordinates (WGS84 format) |
| `room_type` | Text | Property classification: `Entire home/apt`, `Private room`, `Hotel room` or `Shared room` |
| `price` | Currency | Nightly rate listed in New Zealand Dollars (NZD) |
| `minimum_nights` | Integer | Minimum required length of stay in nights |
| `number_of_reviews` | Integer | Total reviews received by the listing |
| `last_review` | Date | Date of the most recent review (`YYYY-MM-DD`) |
| `reviews_per_month` | Numeric | Average number of reviews per month over the lifetime of the listing |
| `calculated_host_listings_count` | Integer | Total number of listings owned by the host at the time of the scrape |
| `availability_365` | Integer | Number of available days in the upcoming 365 days |
| `number_of_reviews_ltm` | Integer | Number of reviews received in the last 12 months |
| `license` | Text | License, permit, or registration number (if applicable under local council regulations) |

### Source and licence

Sourced from Inside Airbnb: <https://insideairbnb.com/get-the-data/>

**Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0).
**Attribution:** Inside Airbnb / Murray Cox.

### Notes

**Room type categories**

- Entire home/apt: guests have access to the entire property.
- Private room: guests have a private bedroom but may share other spaces.
- Hotel room: a room in a hotel or similar accommodation.
- Shared room: guests share the sleeping area with other people.

**`availability_365`**

This value should not be interpreted directly as the number of vacant days. A listing may be unavailable because:

- it has already been booked;
- the host has blocked the date;
- the listing is temporarily inactive; or
- booking restrictions have been applied.

**`reviews_per_month`**

If the number of days between the scrape date and the first review is 30 or fewer:

    reviews_per_month = number_of_reviews

Otherwise:

    reviews_per_month =
        number_of_reviews /
        ((scrape_date - first_review + 1) / (365 / 12))

___

## Bond dataset

File: `01_data/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv.gz`

The dataset contains quarterly rental bond information for different locations, dwelling types and numbers of bedrooms across New Zealand. It includes rental bond counts and weekly rental prices.

| Column Name | Data Type | Description |
|---|---|---|
| `TimeFrame` | Date | Quarter the rental data relates to |
| `Location Id` | Integer | Unique identifier for the location (`NULL` for some national-level rows) |
| `Dwelling Type` | Text | Type of dwelling (`ALL` for all types) |
| `Number Of Beds` | Text | Number of bedrooms in the dwelling (`ALL` for all sizes) |
| `Total Bonds` | Integer | Total number of rental bonds |
| `Active Bonds` | Integer | Number of active rental bonds |
| `Closed Bonds` | Integer | Number of closed rental bonds |
| `Median Rent` | Currency | Median weekly rent in New Zealand Dollars (NZD) |
| `Geometric Mean Rent` | Currency | Average weekly rent calculated using the geometric mean |
| `Upper Quartile Rent` | Currency | Weekly rent at the upper quartile |
| `Lower Quartile Rent` | Currency | Weekly rent at the lower quartile |
| `Log Std Dev Weekly Rent` | Numeric | Measure of variation in weekly rent |

Some rent values are the text `NULL` in the source file. The cleaning script (04) drops the quartile, geometric mean and standard deviation columns and keeps `Median Rent` and the bond counts.

### Source and licence

Sourced from Tenancy Services, Ministry of Business, Innovation and Employment (MBIE): [Rental bond data](https://www.tenancy.govt.nz/about-tenancy-services/data-and-statistics/rental-bond-data/)

Dataset: Detailed Quarterly Report, Q1 2020 – Q3 2026.

**Licence:** Creative Commons Attribution 3.0 New Zealand (CC BY 3.0 NZ).
**Attribution:** Ministry of Business, Innovation and Employment (MBIE).

## Area code data (Koordinates)

Used by script 05 to assign an SA2 to each Airbnb listing.

- **Dataset:** Statistical Area 2 2026
- **Description:** Definitive version of Statistical Area 2 (SA2) boundaries as at 1 January 2026, as defined by Stats NZ. This version contains 2,311 SA2s, excluding the 16 SA2s with empty or null geometries (non-digitised).
- **Layer ID:** 123515
- **Link:** <https://koordinates.com/from/datafinder.stats.govt.nz/layer/123515-statistical-area-2-2026/>
- **Source / data owner:** Stats NZ – Tatauranga Aotearoa
- **Created by:** Geospatial and Data Acquisition Team, Stats NZ
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Attribution:** Stats NZ – Tatauranga Aotearoa
- **Accessed via:** Stats NZ Geographic Data Service / Koordinates

The Christchurch SA2 codes and names are in `01_data/geographic_area_table_2026_chch.csv`.

## Ward / geographic areas data

- **Dataset:** Geographic Areas Table 2023 (meshblock-level concordance)
- **Description:** Stats NZ table mapping every 2023 meshblock to its SA1, SA2, ward, territorial authority and other geographic classifications. Used in `07_full_rental_summarise_ward.R` to attach a ward to each SA2 area code, filtered to `TA2023_name == "Christchurch City"`.
- **Source / data owner:** Stats NZ – Tatauranga Aotearoa
- **Licence:** Creative Commons Attribution 4.0 International (CC BY 4.0)
- **Attribution:** Stats NZ – Tatauranga Aotearoa
- **Accessed via:** Stats NZ Geographic Data Service / Datafinder
- **File:** `01_data/geographic-areas-table-2023.csv.gz`

Notes:
- SA2 codes matched exactly between the 2026 SA2 boundaries (used for the Airbnb area codes) and this 2023-vintage table, for all 179 Christchurch SA2 areas.
- SA2 boundaries don't always sit inside a single ward: 44 of Christchurch's 179 SA2 areas span more than one ward. Each is assigned to whichever ward contains the most meshblocks of that SA2 (the majority ward). See `03_output/full_rental_sa_to_ward_lookup.csv` for the full crosswalk, including how many wards each SA2 touched.
- One SA2 (`363800`) is coded "Area Outside Territorial Authority" in the Stats NZ table and has no ward assigned.