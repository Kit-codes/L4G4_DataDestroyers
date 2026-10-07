# ---------------------------AirBnB Data Cleaning-------------------------

#Description: Cleaning steps for AirBnB data
#1. Takes csv file containing preprocessed airbnb data for Chirstchurch City
#2. Drop columns that have no analytic value in this project
#3. Handles missing prices 
#4. Logs cleaning steps and outcomes to a markdown file


#Inputs: tenancy_chch_preprocessed.csv - csv file containing preprocessed tenancy data for Chirstchurch City
#Outputs: tenancy_chch_cleaned.csv - csv file containing cleaned tenancy data for Chirstchurch City
#         rental_bond_cleaning_log.md - rmarkdown file containing log of cleaning steps and outcomes

#------------------------------load libraries-----------------------------------
library(tidyverse)
library(here)
#----------------------------------INPUT----------------------------------------
# LOAD
tenancy_chch_raw <- read_csv(here("03_output","tenancy_chch_preprocessed.csv"))

n_start <- nrow(tenancy_chch_raw)

#---------------------------cleaning step - remove columns----------------------
# Geometric Mean Rent:
#   removed because `Median Rent` will be used to represent typical long-term rental prices.
# Upper Quartile Rent:
#   not needed because the analysis will use `Median Rent` for rental price comparisons.
# Lower Quartile Rent:
#   not needed because the analysis will use `Median Rent` for rental price comparisons.
# Log Std Dev Weekly Rent:
#   not needed because rental price variation is not part of the planned analysis.

dropped_cols <- c(
  "Geometric Mean Rent", 
  "Upper Quartile Rent", 
  "Lower Quartile Rent", 
  "Log Std Dev Weekly Rent"
)

tenancy_chch_clean <- tenancy_chch_raw |>
                          select(-any_of(dropped_cols))

#---------------------------------check-----------------------------------------

str(tenancy_chch_clean)
#--------------------------------OUTPUT-----------------------------------------

write_csv(tenancy_chch_clean, here("03_output","tenancy_chch_cleaned.csv"))


#------------------------------cleaning log-------------------------------------

n_final <- nrow(tenancy_chch_clean)

log_text <- glue::glue(
  "
# Tenancy Data — Cleaning Log

## Dataset summary

- Input rows: **{n_start}**
- Final rows: **{n_final}**
- Final columns: **{ncol(tenancy_chch_clean)}**

## Columns removed

Four columns were removed because they are not required for the planned analysis in Deliverable 5:

- `Geometric Mean Rent` — removed because `Median Rent` will be used to represent typical long-term rental prices.
- `Upper Quartile Rent` — removed because the analysis will use `Median Rent` for rental price comparisons.
- `Lower Quartile Rent` — removed because the analysis will use `Median Rent` for rental price comparisons.
- `Log Std Dev Weekly Rent` — removed because rental price variation is not part of the planned analysis.

## Final dataset

The cleaned dataset contains **{n_final} rows** and **{ncol(tenancy_chch_clean)} columns**.

The cleaned data was saved as `rental_bond_clean.csv`.
"
)

writeLines(log_text, here("04_documentation", "rental_bond_cleaning_log.md"))






