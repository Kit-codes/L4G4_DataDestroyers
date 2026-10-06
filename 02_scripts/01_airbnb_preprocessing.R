# --- AirBnB Data Pre Processing -----------------------------------------------
# Load libraries
library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))

#--- Load Data -----------------------------------------------------------------
# Every listings_YYYY_MM.csv in 01_data/01_airbnb_rawdata
airbnb_months <- get_airbnb_months()
  
#--- Create merged file --------------------------------------------------------
# Read all New Zealand listings files and add year_month column
nz_data_all <- map2_dfr(
  airbnb_months$file,
  airbnb_months$year_month,
  ~ read_csv(.x) |>
    mutate(year_month = .y)
)

#--- Filter Christchurch city listings -----------------------------------------
chch_data_all <- nz_data_all |>
  filter(neighbourhood_group == "Christchurch City")

#--- Output --------------------------------------------------------------------
write_csv(nz_data_all, here("03_output", "airbnb_nz_preprocessed.csv"))
write_csv(chch_data_all, here("03_output","airbnb_chch_preprocessed.csv"))