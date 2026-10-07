# ---------------------------Tenancy Data Pre Processing-------------------------

#Description: Pre-processioning for Tenancy data
#1. Takes CSV containing Quarterly Tenancy Data for all New Zealand
#2. Filters on date range October 2025 - June 2026
#3. Filters the data on location to include only listings with Christchurch area codes

#Inputs: Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv - raw tenancy data set
#        geographic_area_table_2026_chch.csv - lookup table for Christchurch area codes
#Outputs: tenancy_nz_preprocessed.csv - csv file containing tenancy data for all of New Zealand
#         tenancy_chch_preprocessed.csv - csv file containing tenancy data for Christchurch City


#------------------------------load libraries-----------------------------------

library(tidyverse)
library(here)
#----------------------------------INPUT----------------------------------------

# 1. read tenancy data file
tenancy_data_full <- read_csv(here("01_data","Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv"))
chch_areas <- read_csv(here("01_data", "geographic_area_table_2026_chch.csv"))

#-----------------------------filter on date range------------------------------
# filter dataset to only include dates from 01 October 2025 to 30 June 2026
tenancy_data_current <- tenancy_data_full |>
                  filter(between(TimeFrame,as.Date("2025-10-01"), as.Date("2026-06-30")))
      

#-------------------------filter on Christchurch City---------------------------
tenancy_data_chch <- tenancy_data_current |>
  filter(
    `Location Id` %in% chch_areas$SA22026_code
  )


#--------------------------------OUTPUT-----------------------------------------
#OUTPUT
write_csv(tenancy_data_current, here("03_output","tenancy_nz_preprocessed.csv"))
write_csv(tenancy_data_chch, here("03_output","tenancy_chch_preprocessed.csv"))
