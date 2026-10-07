# ---------------------------AirBnB Data Pre Processing-------------------------

#Description: Pre-processioning for AirBnB data
#1. Takes folder of csv files containing monthly AirBnB listing data for New Zealand
#2. Extracts the month and year from the csv file names and writes to a new 'year_month' column,
#3. Merges the data files into a single New Zealand data set
#4. Filters New Zealand data set on Christchurch City neighborhood group.


#Inputs: 01_airbnb_rawdata - file folder containing csv files of monthly listings data
#Outputs: airbnb_nz_preprocessed.csv - csv file containing AirBnB listings data for all of New Zealand
#         airbnb_chch_preprocessed.csv - csv file containing AirBnB listings data for Christchurch City


#------------------------------load libraries-----------------------------------
library(tidyverse)
library(here) 

#----------------------------------INPUT----------------------------------------

listings_folder <- here("01_data","01_airbnb_rawdata")

listings_files = list.files(
  path = listings_folder,
  pattern = "\\.csv$",
  full.names = TRUE
  
  
)
#-----------------------------create merged file--------------------------------

#read all New Zealand listings files and add year_month column
nz_data_all <- map_dfr(
  listings_files,
  ~ read_csv(.x) |>
    mutate(
      year_month = str_extract(basename(.x), "\\d{4}_\\d{2}")
    )
)
#------------------------filter on Christchurch City----------------------------

# 5. filter Christchurch city listings
chch_data_all <- nz_data_all |>
  filter(neighbourhood_group == "Christchurch City")


#--------------------------------OUTPUT-----------------------------------------

#save all New Zealand listings and Christchurch listings to csv file.

write_csv(nz_data_all, here("03_output", "airbnb_nz_preprocessed.csv"))
write_csv(chch_data_all, here("03_output","airbnb_chch_preprocessed.csv"))



