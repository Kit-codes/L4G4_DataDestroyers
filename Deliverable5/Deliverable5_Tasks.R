library(tidyverse)
library(dplyr)

full_summary <- read.csv("~/L4G4_DataDestroyers/output/cleaned/full_summary.csv.gz")


#find median price of christchurch central Airbnbs

median_chch_central <- full_summary[full_summary$SA22026_name == "Christchurch Central","median_Airbnb_price"]
median_chch_central[1]
#-------------------------------------------------------------------------------------------------------

#find the area in Christchurch that has the largest difference in rental and airbnb Price
full_summary$median_rent_per_night <- full_summary$Median_rent/7

full_summary$price_diff_per_night <- abs(full_summary$median_Airbnb_price - full_summary$median_rent_per_night)

max_price_diff<- full_summary |> 
                  slice_max(price_diff_per_night, n = 1)

max_price_diff


