#--- Join ----------------------------------------------------------------------
# Median price for Chistchurch central Airbnb properties
# Load Libraries
library(tidyverse)
library(dplyr)
library(here)

#--- Load Data -----------------------------------------------------------------
full_summary <- read.csv(here("03_output","full_rental_summary_bylocation.csv"))


#--- Join Operation ------------------------------------------------------------
# Find median price of Christchurch central Airbnbs
median_chch_central <- full_summary[full_summary$SA22026_name == "Christchurch Central",
                                    "median_Airbnb_price"]
median_chch_central[1]




