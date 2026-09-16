# 1. load library --------------------------------------------------------

library(tidyverse)


# 2. setup paths ---------------------------------------------------------
input_file    <- file.path("output","merged", "tenancy_data.csv")
chcharea_file <- file.path("resource", "geographic_area_table_2026_chch.csv")
cleaned_dir   <- file.path("output", "cleaned")
output_file   <- file.path(cleaned_dir, "rental_bond_clean.csv.gz")
log_file      <- file.path(cleaned_dir, "rental_bond_cleaning_log.md")
dir.create(cleaned_dir, recursive = TRUE, showWarnings = FALSE)


# 3. load data ----
raw <- read_csv(input_file)
n_start <- nrow(raw)

chch_areas <- read_csv(chcharea_file)

chch_areas <- chch_areas |>
  mutate(
    SA22026_code = as.character(SA22026_code)
  )


# 4. dropped columns with no analytical value ------------------------------

# Based on Deliverable 5
# 
# Geometric Mean Rent
#   removed because `Median Rent` will be used to represent typical long-term rental prices.
# Upper Quartile Rent
#   not needed because the analysis will use `Median Rent` for rental price comparisons.
# Lower Quartile Rent
#   not needed because the analysis will use `Median Rent` for rental price comparisons.
# Log Std Dev Weekly Rent
#   not needed because rental price variation is not part of the planned analysis.

dropped_cols <- c(
  "Geometric Mean Rent", 
  "Upper Quartile Rent", 
  "Lower Quartile Rent", 
  "Log Std Dev Weekly Rent"
)

clean <- raw |>
  select(-any_of(dropped_cols))


# 5. filter relevant rows ------------------------------------------------


# The analysis focuses on Christchurch. 
# `SA22026_code` from the Christchurch geographic area table was matched 
# with `Location Id` in the rental bond dataset.
n_before_location <- nrow(clean)

clean <- clean |>
  filter(
    `Location.Id` %in% chch_areas$SA22026_code
  )

n_after_location <- nrow(clean)
n_location_removed <- n_before_location - n_after_location


# 6. Save cleaned data ----------------------------------------------------

write_csv(clean, output_file)


# 7. Create cleaning log -------------------------------------------------

n_final <- nrow(clean)

log_text <- glue::glue(
  "
# Rental Bond Data — Cleaning Log

## Dataset summary

- Input rows: **{n_start}**
- Final rows: **{n_final}**
- Final columns: **{ncol(clean)}**

## Columns removed

Four columns were removed because they are not required for the planned analysis in Deliverable 5:

- `Geometric Mean Rent` — removed because `Median Rent` will be used to represent typical long-term rental prices.
- `Upper Quartile Rent` — removed because the analysis will use `Median Rent` for rental price comparisons.
- `Lower Quartile Rent` — removed because the analysis will use `Median Rent` for rental price comparisons.
- `Log Std Dev Weekly Rent` — removed because rental price variation is not part of the planned analysis.


## Location filtering

The analysis focuses on Christchurch. `SA22026_code` from the Christchurch geographic area table was matched with `Location Id` in the rental bond dataset.

Rows before Christchurch filtering: **{n_before_location}**

Rows after Christchurch filtering: **{n_after_location}**

Rows removed: **{n_location_removed}**

### Note:
Rows that contain Number of Beds = 'ALL' and 'NA' have been identified, but retained at this stage, as the number of bed is currently not in use, and the loss of data is significant (94305 rows from raw, 7280 from chritchurch area )

## Final dataset

The cleaned dataset contains **{n_final} rows** and **{ncol(clean)} columns**.

The cleaned data was saved as `rental_bond_clean.csv.gz`.
"
)

writeLines(log_text, log_file)






