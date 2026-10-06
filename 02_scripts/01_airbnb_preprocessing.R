# --- AirBnB Data Pre Processing -----------------------------------------------
# Load libraries
library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))

#--- Load Data -----------------------------------------------------------------
# Every listings_YYYY_MM.csv in 01_data/01_airbnb_rawdata
cfg <- get_config()
airbnb_months <- get_airbnb_months()
check_month_gaps(airbnb_months$year_month)

listings_cols <- c("id", "host_id", "neighbourhood_group", "neighbourhood",
                   "latitude", "longitude", "room_type", "price", "minimum_nights",
                   "number_of_reviews", "last_review", "reviews_per_month",
                   "calculated_host_listings_count", "availability_365",
                   "number_of_reviews_ltm")

#--- Create merged file --------------------------------------------------------
# Read all New Zealand listings files and add year_month column
nz_data_all <- map2_dfr(
  airbnb_months$file,
  airbnb_months$year_month,
  ~ read_csv(.x) |>
    check_columns(listings_cols, basename(.x)) |>
    mutate(year_month = .y)
)

#--- Filter listings -----------------------------------------------------------
chch_data_all <- nz_data_all |>
  filter(neighbourhood_group == cfg$area)

#--- Checks --------------------------------------------------------------------
if (nrow(chch_data_all) == 0) {
  stop("No listings with neighbourhood_group == '", cfg$area, "'. Check area in config.yaml.")
}
if (anyNA(chch_data_all$latitude) || anyNA(chch_data_all$longitude)) {
  warning(sum(is.na(chch_data_all$latitude) | is.na(chch_data_all$longitude)),
          " listing(s) have no coordinates and will get no area code")
}

#--- Output --------------------------------------------------------------------
write_csv(nz_data_all, here("03_output", "airbnb_nz_preprocessed.csv"))
write_csv(chch_data_all, here("03_output","airbnb_chch_preprocessed.csv"))