#------------------------------------------------------------------------------- 
# Tenancy Data Pre Processing
# Date: 16/9/2026

library(tidyverse)
library(here)
#-------------------------------------------------------------------------------
#LOAD DATA
# 1. read tenancy data file
tenancy_data_full <- read_csv(here("1_data","Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv"))

#-------------------------------------------------------------------------------
# filter dataset to only include dates from 01 October 2025 to 30 June 2026
tenancy_data <- tenancy_data_full |>
                  filter(between(TimeFrame,as.Date("2025-10-01"), as.Date("2026-06-30")))
      

#-------------------------------------------------------------------------------
#OUTPUT
write_csv(tenancy_data, here("3_output","tenancy_full.csv"))

