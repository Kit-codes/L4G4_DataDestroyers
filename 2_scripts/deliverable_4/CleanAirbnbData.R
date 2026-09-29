# 1. install tidyverse packages, un comment only need run it once. ----
# install.packages("tidyverse")


# 2. load library --------------------------------------------------------

library(tidyverse)

# source('my_tools/data_summary.R') # look like this code was never used.


# 3. setup paths ---------------------------------------------------------
input_file   <- file.path("output", "merged", "chch_merged_files.csv")
cleaned_dir  <- file.path("output", "cleaned")
output_file  <- file.path(cleaned_dir, "chch_listings_clean.csv.gz")
log_file     <- file.path(cleaned_dir, "chch_cleaning_log.md")
dir.create(cleaned_dir, recursive = TRUE, showWarnings = FALSE)


# 4. load data ----
raw <- read_csv(input_file)
n_start <- nrow(raw)


# 5. dropped columns with no analytical value ------------------------------

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

clean <- raw |>
  select(-any_of(dropped_cols))


# 6. Handle missing prices ------------------------------------------------

# price is important to next week's rent comparison with the bond dataset,so rows 
# with no price are not usable for that purpose. We drop them rather than impute, 
# since imputing a price would fabricate rent data.


n_before_price <- nrow(clean)

clean <- clean |>
  filter(!is.na(price))

n_after_price <- nrow(clean)

n_price_dropped <- n_before_price - n_after_price


# 7. Save cleaned data ----------------------------------------------------

write_csv(clean, output_file)


# 8. Create cleaning log --------------------------------------------------

log_text <- glue::glue(
  "
# Christchurch Listings - Cleaning Log

## Dataset summary

- Rows in input dataset: **{n_start}**
- Rows in cleaned dataset: **{nrow(clean)}**

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

writeLines(log_text, log_file)









