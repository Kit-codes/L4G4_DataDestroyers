#-------------------------------------------------------------------------------
# Tenancy Christchurch Data Cleaning

library(tidyverse)
library(here)
#------------------------------------------------------------------------------
# LOAD
tenancy_chch_raw <- read_csv(here("3_output", "tenancy_chch_preprocessed.csv"))

n_start <- nrow(tenancy_chch_raw)

#------------------------------------------------------------------------------
# Cleaning step - remove columns
# Based on Deliverable 5
#
# Geometric Mean Rent, Upper Quartile Rent, Lower Quartile Rent:
#   not needed because `Median Rent` is used for rental price comparisons.
# Log Std Dev Weekly Rent:
#   rental price variation is not part of the planned analysis.
#
# NB: read_csv() keeps the spaces in column names, so the names below use spaces.

dropped_cols <- c(
  "Geometric Mean Rent",
  "Upper Quartile Rent",
  "Lower Quartile Rent",
  "Log Std Dev Weekly Rent"
)

# sanity check: every column we want to drop must exist
stopifnot(all(dropped_cols %in% names(tenancy_chch_raw)))

tenancy_chch_clean <- tenancy_chch_raw |>
  select(-all_of(dropped_cols))

# sanity check: exactly those columns were removed
stopifnot(ncol(tenancy_chch_clean) == ncol(tenancy_chch_raw) - length(dropped_cols))

#-------------------------------------------------------------------------------
# OUTPUT
write_csv(tenancy_chch_clean, here("3_output", "tenancy_chch_cleaned.csv"))


#-------------------------------------------------------------------------------
# CLEANING LOG
n_final <- nrow(tenancy_chch_clean)

log_text <- glue::glue(
  "
# Rental Bond Data - Cleaning Log

## Dataset summary

- Input rows: **{n_start}**
- Final rows: **{n_final}**
- Final columns: **{ncol(tenancy_chch_clean)}**

## Columns removed

Four columns were removed because they are not required for the planned analysis:

- `Geometric Mean Rent` - `Median Rent` is used to represent typical long-term rental prices.
- `Upper Quartile Rent` - the analysis uses `Median Rent` for rental price comparisons.
- `Lower Quartile Rent` - the analysis uses `Median Rent` for rental price comparisons.
- `Log Std Dev Weekly Rent` - rental price variation is not part of the planned analysis.

## Final dataset

The cleaned dataset contains **{n_final} rows** and **{ncol(tenancy_chch_clean)} columns**.

The cleaned data was saved as `tenancy_chch_cleaned.csv`.
"
)

writeLines(log_text, here("4_documentation", "rental_bond_cleaning_log.md"))