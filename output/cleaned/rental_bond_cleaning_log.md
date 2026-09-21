# Rental Bond Data — Cleaning Log

## Dataset summary

- Input rows: **226080**
- Final rows: **2170**
- Final columns: **8**

## Columns removed

Four columns were removed because they are not required for the planned analysis in Deliverable 5:

- `Geometric Mean Rent` — removed because `Median Rent` will be used to represent typical long-term rental prices.
- `Upper Quartile Rent` — removed because the analysis will use `Median Rent` for rental price comparisons.
- `Lower Quartile Rent` — removed because the analysis will use `Median Rent` for rental price comparisons.
- `Log Std Dev Weekly Rent` — removed because rental price variation is not part of the planned analysis.

## Time filtering

The Airbnb dataset covers October 2025 to June 2026. The rental bond data was therefore restricted to the corresponding quarterly periods:

- 2025-10-01
- 2026-01-01
- 2026-04-01

Rows before time filtering: **226080**

Rows after time filtering: **27212**

Rows removed: **198868**

## Location filtering

The analysis focuses on Christchurch. `SA22026_code` from the Christchurch geographic area table was matched with `Location Id` in the rental bond dataset.

Rows before Christchurch filtering: **27212**

Rows after Christchurch filtering: **2170**

Rows removed: **25042**

## Missing values

`Number Of Beds` contains **92** missing values in the final dataset.

These rows were retained because `Number Of Beds` is not required for the main join in Deliverable 5. The main join uses `Location Id` and `TimeFrame`, so removing these rows could discard otherwise useful rental records.

## Duplicates

No duplicated rows were found in the cleaned dataset.

## Final dataset

The cleaned dataset contains **2170 rows** and **8 columns**.

The cleaned data was saved as `rental_bond_clean.csv.gz`.
