#####################
# Tenancy Data Cleaning
# Date: 16/9/2026
####################

library(tidyverse)


# 3. setup paths
input_file   <- file.path("resource", "merged", "tenancy_data.csv")
cleaned_dir  <- file.path("resource", "cleaned")
output_file  <- file.path(cleaned_dir, "tenancy_clean.csv.gz")
log_file     <- file.path(cleaned_dir, "tenancy_cleaning_log.md")
dir.create(cleaned_dir, recursive = TRUE)


# 4. load data
raw <- read_csv(input_file)
n_start <- nrow(raw)


# 5. decision log (accumulated as we)
log_lines <- c(
  "# Christchurch Listings — Cleaning Log",
  "",
  paste0("Rows in input file: **", n_start, "**"),
  "",
  "## Columns dropped",
  ""
)


# 4. dropped columns with no analytical value 

# license: 100% missing in this data set: zero information, drop entirely
# neighbourhood_group: constant "Christchurch City", no analytical value
# name, host_name: personal-identifier columns not needed for numeric analysis, 
#                   also privacy considerations.

dropped_cols <- c("license", "neighbourhood_group", "name", "host_name")

log_lines <- c(log_lines,
               "- `license` — 100% missing (0 non-NA values); carries no information.",
               "- `neighbourhood_group` — constant value ('Christchurch City') after Deliverable 3 filtering; no variance.",
               "- `name` — free-text listing title, not used in numeric analysis.",
               "- `host_name` — personal identifier, privacy-adjacent, not needed for analysis.",
               ""
)

clean <- raw |>
  select(-any_of(dropped_cols))


# 5. Handle missing prices 

# price is important to next week's rent comparison with the bond dataset,so rows 
# with no price are not usable for that purpose. We drop them rather than impute, 
# since imputing a price would fabricate rent data.

n_before_price <- nrow(clean)
clean <- clean |>
  filter(!is.na(price))
n_after_price <- nrow(clean)
price_dropped <- n_before_price - n_after_price

log_lines <- c(log_lines,
               "## Rows dropped",
               "",
               paste0(
                 "- Missing `price`: dropped ", price_dropped, " rows (",
                 round(100 * price_dropped / n_before_price, 1),
                 "% of rows at that point). Reason: price is required for the rent ",
                 "comparison planned for next week's deliverable, and imputing it ",
                 "would fabricate rent figures rather than reflect real listings."
               ),
               ""
)

