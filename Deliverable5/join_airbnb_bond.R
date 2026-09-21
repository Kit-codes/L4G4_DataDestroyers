# 1. install packages, uncomment if needed -----------------------------------

# install.packages("tidyverse")
# install.packages("lubridate")


# 2. load packages ------------------------------------------------------------

library(tidyverse)
library(lubridate)


# 3. setup paths ---------------------------------------------------------------

airbnb_file <- file.path(
  "output",
  "cleaned",
  "chch_listings_with_area.csv.gz"
)

bond_file <- file.path(
  "output",
  "cleaned",
  "rental_bond_clean.csv.gz"
)

output_dir <- file.path(
  "output",
  "cleaned"
)

# Join with all bond categories
output_all <- file.path(
  output_dir,
  "airbnb_bond_join_all.csv.gz"
)

dir.create(
  output_dir,
  recursive = TRUE,
  showWarnings = FALSE
)


# 4. load data ----------------------------------------------------------------

airbnb <- read_csv(
  airbnb_file,
  col_types = cols(
    id = col_character(),
    host_id = col_character(),
    SA22026_code = col_character()
  )
)

bond <- read_csv(
  bond_file,
  col_types = cols(
    `Location Id` = col_character()
  )
)


# 5. check required columns ---------------------------------------------------

airbnb_required <- c(
  "SA22026_code",
  "year_month"
)

bond_required <- c(
  "TimeFrame",
  "Location Id",
  "Dwelling Type",
  "Number Of Beds",
  "Median Rent"
)

missing_airbnb <- setdiff(
  airbnb_required,
  names(airbnb)
)

missing_bond <- setdiff(
  bond_required,
  names(bond)
)

if (length(missing_airbnb) > 0) {
  stop(
    "Missing Airbnb columns: ",
    paste(missing_airbnb, collapse = ", ")
  )
}

if (length(missing_bond) > 0) {
  stop(
    "Missing bond columns: ",
    paste(missing_bond, collapse = ", ")
  )
}


# 6. create a common time variable -------------------------------------------
#
# Airbnb is monthly:
#   2025_10
#   2025_11
#   2026_03
#   ...
#
# Bond is quarterly:
#   2025/10/01
#   2026/01/01
#   2026/04/01
#
# Convert both to quarter_start so they can be joined on the same time unit.

airbnb <- airbnb |>
  mutate(
    month_date = year_month |>
      str_replace("_", "-") |>
      paste0("-01") |>
      ymd(),
    
    quarter_start = floor_date(
      month_date,
      unit = "quarter"
    )
  )

bond <- bond |>
  mutate(
    quarter_start = ymd(TimeFrame)
  )


# 7. check the common area codes and time periods ----------------------------

common_area_codes <- intersect(
  unique(airbnb$SA22026_code),
  unique(bond$`Location Id`)
)

common_quarters <- intersect(
  unique(airbnb$quarter_start),
  unique(bond$quarter_start)
)

cat(
  "\nAirbnb SA2 codes:",
  n_distinct(airbnb$SA22026_code),
  "\n"
)

cat(
  "Bond location IDs:",
  n_distinct(bond$`Location Id`),
  "\n"
)

cat(
  "Common area codes:",
  length(common_area_codes),
  "\n"
)

cat(
  "Common quarters:",
  length(common_quarters),
  "\n\n"
)


# 8. join two dataset ---------------------------------------------------------



airbnb_bond_all <- airbnb |>
  full_join(
    bond,
    by = c(
      "SA22026_code" = "Location Id",
      "quarter_start"
    ),
    relationship = "many-to-many"
  )


# 9. check full join -----------------------------------------------------------

cat(
  "Airbnb rows before full join:",
  nrow(airbnb),
  "\n"
)

cat(
  "Rows after full join:",
  nrow(airbnb_bond_all),
  "\n"
)

cat(
  "Additional rows created:",
  nrow(airbnb_bond_all) - nrow(airbnb),
  "\n\n"
)

full_join_summary <- airbnb_bond_all |>
  summarise(
    total_rows = n(),
    
    matched_rows = sum(
      !is.na(id) & !is.na(TimeFrame)
    ),
    
    airbnb_only_rows = sum(
      !is.na(id) & is.na(TimeFrame)
    ),
    
    bond_only_rows = sum(
      is.na(id) & !is.na(TimeFrame)
    )
  )

print(full_join_summary)


# 10. save full join ------------------------------------------------------------

write_csv(
  airbnb_bond_all,
  output_all
)


# 11. finish ------------------------------------------------------------------

cat(
  "\nSaved full bond join to:\n",
  output_all,
  "\n"
)

