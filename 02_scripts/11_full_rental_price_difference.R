#--- Price Difference in Full Data Set -----------------------------------------
# Find the location with the  maximum difference in price per night between 
# Airbnb and long term rentals
#
# Load Libraries
library(tidyverse)
library(here)
library(dplyr)

#--- Load Data -----------------------------------------------------------------
full_summary <- read.csv(here("03_output","full_rental_summary_bylocation.csv"))

#--- Calculations --------------------------------------------------------------
# Add a per night price for tenancy to df
full_summary$median_rent_per_night <- full_summary$Median_rent/7

# Calculate the difference in price between airbnb and tenancy
full_summary$price_diff_per_night <- abs(full_summary$median_Airbnb_price - full_summary$median_rent_per_night)

# Find the row with the largest diffeence in price
max_price_diff<- full_summary |> 
                    slice_max(price_diff_per_night, n = 1)
max_price_diff

#--- Output --------------------------------------------------------------
write_csv(full_summary, here("03_output","full_rental_summary_withpricediff.csv"))

