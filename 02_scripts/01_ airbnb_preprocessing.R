# ------------------------------------------------------------------------------
#AirBnB Data Pre Processing
#
#load libraries
library(tidyverse)
library(here)
#-------------------------------------------------------------------------------
#LOAD DATA

listings_folder <- here("01_data","01_airbnb_rawdata")

listings_files = list.files(
                    path = listings_folder,
                    pattern = "\\.csv$",
                    full.names = TRUE
                  )
#-------------------------------------------------------------------------------
#Create merged file
#read all new zealand listings files and add year_month column
nz_data_all <- map_dfr(
                listings_files,
                ~ read_csv(.x) |>
                  mutate(
                    year_month = str_extract(basename(.x), "\\d{4}_\\d{2}")
                  )
              )

# 5. filter Christchurch city listings
chch_data_all <- nz_data_all |>
                    filter(neighbourhood_group == "Christchurch City")


#-------------------------------------------------------------------------------
#OUTPUT
#save all New Zealand listings and Christchurch listings to csv file.

write_csv(nz_data_all, here("03_output", "airbnb_nz_preprocessed.csv"))
write_csv(chch_data_all, here("03_output","airbnb_chch_preprocessed.csv"))



