#--- AirBnB Christchurch Data Cleaning -----------------------------------------

# Description: takes preprocessed Airbnb listings data for Christchurch City,
#              removes columns that are unnecessary for analysis
#              handles missing prices 
#              writes cleaned data to csv
#              writes cleaning log and outcomes to rmarkdown file

# Inputs: airbnb_chch_preprocessed.csv - csv file containing pre processed airbnb listings data

# Outputs: airbnb_chch_cleaned.csv - csv file containing cleaned airbnb listings data
#          chch_cleaning_log.md - rmarkdown file containing cleaning log and outcomes

#--- Load libraries ------------------------------------------------------------
library(tidyverse)
library(here)

#--- Load Data -----------------------------------------------------------------
airbnb_chch_raw <- read_csv(
  here("03_output", "airbnb_chch_preprocessed.csv"),
  col_types = cols(
    id = col_character(),
    host_id = col_character(),
    last_review = col_character()
  )
)
n_start <- nrow(airbnb_chch_raw)

#--- Cleaning step - remove columns --------------------------------------------

# license: 
#   100% missing in this data set: zero information, drop entirely
#
# neighbourhood_group: 
#   constant "Christchurch City", no analytical value
#
# name, host_name: 
#   personal-identifier columns not needed for numeric analysis, 
#   also privacy considerations.

dropped_cols <- c(
  "license", 
  "neighbourhood_group", 
  "name", 
  "host_name"
)

airbnb_chch_clean <- airbnb_chch_raw|>
                        select(-any_of(dropped_cols))

#--- Cleaning Step - handle missing prices -------------------------------------

# price is important to next week's rent comparison with the bond dataset,so rows 
# with no price are not usable for that purpose. We drop them rather than impute, 
# since imputing a price would fabricate rent data.


n_before_price <- nrow(airbnb_chch_clean)

airbnb_chch_clean <- airbnb_chch_clean |>
                        filter(!is.na(price))

#Document Step
n_after_price <- nrow(airbnb_chch_clean)
n_price_dropped <- n_before_price - n_after_price

#--- Check ---------------------------------------------------------------------
str(airbnb_chch_clean)

expected_rows <- nrow(airbnb_chch_raw) -
  sum(is.na(airbnb_chch_raw$price))

if (!isTRUE(nrow(airbnb_chch_clean) == expected_rows)) {
  stop(
    "03: Cleaned row count does not match input rows minus missing-price rows.",
    call. = FALSE
  )
}

if (anyNA(airbnb_chch_clean$price)) {
  stop(
    "03: Missing prices remain after cleaning.",
    call. = FALSE
  )
}

if (any(dropped_cols %in% names(airbnb_chch_clean))) {
  stop(
    "03: Columns intended for removal are still present.",
    call. = FALSE
  )
}

#--- Output --------------------------------------------------------------------
write_csv(airbnb_chch_clean, here("03_output","airbnb_chch_cleaned.csv"))

#--- Cleaning Log --------------------------------------------------------------
log_text <- glue::glue(
  "
# Christchurch Listings - Cleaning Log

## Dataset summary

- Rows in input dataset: **{n_start}**
- Rows in cleaned dataset: **{nrow(airbnb_chch_clean)}**

## Columns removed

- `license`: all values were missing, and not needed for analysis
- `neighbourhood_group`: constant after Christchurch filtering.
- `name`: listing title not required for the planned analysis.
- `host_name`: not required for the planned analysis.

## Rows removed

- Missing `price`: **{n_price_dropped}** rows
  ({round(100 * n_price_dropped / n_before_price, 1)}%).

`price` is required for the planned comparison with rental bond data.
Missing prices were not imputed because this would create values that
were not observed in the original listings.
"
)

writeLines(log_text,here("04_documentation","chch_cleaning_log.md"))









