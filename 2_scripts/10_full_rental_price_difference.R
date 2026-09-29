#-------------------------------------------------------------------------------
#Find the loaction with the  maximum difference in price per night between airbnb and long term rentals

library(tidyverse)
library(dplyr)
#-------------------------------------------------------------------------------------------------------
full_summary <- read.csv(here("3_output","full_rental_summary_bylocation.csv"))


#add a per night price for tenancy to df
full_summary$median_rent_per_night <- full_summary$Median_rent/7

# caluclate the difference in price between airbnb and tenancy
full_summary$price_diff_per_night <- abs(full_summary$median_Airbnb_price - full_summary$median_rent_per_night)


# find the row with the largest diffeence in price
max_price_diff<- full_summary |> 
                    slice_max(price_diff_per_night, n = 1)

max_price_diff

write_csv(full_summary, here("3_output","full_rental_summary_withpricediff.csv"))

