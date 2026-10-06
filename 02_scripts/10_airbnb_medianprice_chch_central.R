#-------------------------------------------------------------------------------
#Median price for chistchurch central airbnb properties

library(tidyverse)
library(dplyr)
library(here)
#-------------------------------------------------------------------------------
full_summary <- read.csv(here("03_output","full_rental_summary_bylocation.csv"))


#find median price of Christchurch central Airbnbs

median_chch_central <- full_summary[full_summary$SA22026_name == "Christchurch Central","median_Airbnb_price"]
median_chch_central[1]




