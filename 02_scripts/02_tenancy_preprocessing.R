# --- Tenancy Data Preprocessing ------------------------------------------------

#Description: Takes raw tenancy listing data files, 
#             Filters on dates to match airbnb data - pulled from config.R
#             filters on Christchurch City and creates a second Christchurch data set


#Inputs: Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv - csv file of quarterly tenancy data
#        geographic_area_table_2026_chch.csv
#Outputs: tenancy_nz_preprocessed.csv - csv file containing tenancy data for all of New Zealand
#         tenancy_chch_preprocessed.csv - csv file containing tenancy data for Christchurch City

#---Load Libraries -------------------------------------------------------------
library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))

#--- Load Data -----------------------------------------------------------------
# Read tenancy data file
tenancy_data_full <- read_csv(here("01_data","Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv")) |>
  check_columns(c("TimeFrame", "Location Id", "Dwelling Type", "Number Of Beds",
                  "Total Bonds", "Active Bonds", "Closed Bonds", "Median Rent",
                  "Geometric Mean Rent", "Upper Quartile Rent",
                  "Lower Quartile Rent", "Log Std Dev Weekly Rent"),
                "tenancy data")

# Read Chch data file
chch_areas <- read_csv(here("01_data", "geographic_area_table_2026_chch.csv")) |>
  check_columns(c("SA22026_code", "SA22026_name"), "geographic_area_table_2026_chch.csv")

#--- Filter Dataset ------------------------------------------------------------
# Data is filtered to only cover period available in the Airbnb months in 
# 01_data/01_airbnb_rawdata (first day of the earliest month to last day of the 
# latest month)
window_start <- month_start(earliest_airbnb_month())
window_end   <- month_end(latest_airbnb_month())
message("Tenancy window: ", window_start, " to ", window_end)
tenancy_data_current <- tenancy_data_full |>
  filter(between(TimeFrame, window_start, window_end))

if (nrow(tenancy_data_current) == 0) {
  stop("No tenancy data between ", window_start, " and ", window_end,
       ". The tenancy file does not cover the Airbnb months yet.")
}

tenancy_data_chch <- tenancy_data_current |>
  filter(
    `Location Id` %in% chch_areas$SA22026_code
  )

#--- Output --------------------------------------------------------------------
write_csv(tenancy_data_current, here("03_output","tenancy_nz_preprocessed.csv"))
write_csv(tenancy_data_chch, here("03_output","tenancy_chch_preprocessed.csv"))
