#####################
# Tenancy Data Preprocessing
# Date: 16/9/2026
####################


library(tidyverse)

# 1. read tenancy data file

save_path <- file.path("resource", "merged","tenancy_data.csv")
tenancy_data_full <- read.csv ("resource/tenancy_rawdata/tenancy_2020Q1_2026_Q3.csv")

                         
# filter dataset  to only include dates from 01 October 2025 to 30 June 2026
tenancy_data <- tenancy_data_full |>
  filter(between(TimeFrame,"2025-10-01", "2026-06-30")) 
      

# 6. save all New Zealand listings and Christchurch listings to csv file.
write_csv(tenancy_data, save_path)
