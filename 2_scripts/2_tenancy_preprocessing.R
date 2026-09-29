#------------------------------------------------------------------------------- 
# Tenancy Data Pre Processing
# Date: 16/9/2026

library(tidyverse)
library(here)
#-------------------------------------------------------------------------------
#LOAD DATA
# 1. read tenancy data file
tenancy_data_full <- read_csv(here("1_data","Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv"))
chch_areas <- read_csv(here("1_data", "geographic_area_table_2026_chch.csv"))
#-------------------------------------------------------------------------------
# filter dataset to only include dates from 01 October 2025 to 30 June 2026
tenancy_data_current <- tenancy_data_full |>
                  filter(between(TimeFrame,as.Date("2025-10-01"), as.Date("2026-06-30")))
      

#
tenancy_data_chch <- tenancy_data_current |>
  filter(
    `Location Id` %in% chch_areas$SA22026_code
  )




#-------------------------------------------------------------------------------
#OUTPUT
write_csv(tenancy_data_current, here("3_output","tenancy_nz_preprocessed.csv"))
write_csv(tenancy_data_chch, here("3_output","tenancy_chch_preprocessed.csv"))
