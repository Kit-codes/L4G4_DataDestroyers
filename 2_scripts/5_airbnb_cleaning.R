#-------------------------------------------------------------------------------
#AirBnB Christchurch Data Cleaning


library(tidyverse)
library(here)
#------------------------------------------------------------------------------
#LOAD DATA
airbnb_chch_raw <- read_csv(here("3_output", "airbnb_chch_preprocessed.csv"))

n_start <- nrow(airbnb_chch_raw)

#------------------------------------------------------------------------------
#Cleaning step - remove columns

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

#-------------------------------------------------------------------------------
# Cleaning Step - Handle missing prices 

# price is important to next week's rent comparison with the bond dataset,so rows 
# with no price are not usable for that purpose. We drop them rather than impute, 
# since imputing a price would fabricate rent data.


n_before_price <- nrow(airbnb_chch_clean)

airbnb_chch_clean <- airbnb_chch_clean |>
                        filter(!is.na(price))

#Document Step
n_after_price <- nrow(airbnb_chch_clean)
n_price_dropped <- n_before_price - n_after_price


#-------------------------------------------------------------------------------
#OUPUT
write_csv(airbnb_chch_clean, here("3_output","airbnb_chch_cleaned.csv"))


#-------------------------------------------------------------------------------
#CLEANING LOG
log_text <- glue::glue(
  "
# Christchurch Listings - Cleaning Log

## Dataset summary

- Rows in input dataset: **{n_start}**
- Rows in cleaned dataset: **{nrow(airbnb_chch_clean)}**

## Columns removed

- `license`: all values were missing.
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

writeLines(log_text,here("4_documentation","chch_cleaning_log.md"))









