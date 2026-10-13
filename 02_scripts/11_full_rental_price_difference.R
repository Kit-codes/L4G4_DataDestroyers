#--- Price Difference Between Tenancy and Airbnb -------------------------------
#Description: Calculates the price difference between long term and short term rentals for Christchurch locations, by suburb


# Inputs: full_rental_summary_bylocation.csv - csv file containing aribnb and tenancy data by location (suburb level)
#         

# Outputs: full_rental_summary_withpricediff.csv - csv file containing the full rental summary with price difference column

#--- Load libraries ------------------------------------------------------------
library(tidyverse)
library(here)
library(dplyr)

#--- Load Data -----------------------------------------------------------------
full_summary <- read.csv(here("03_output","full_rental_summary_bylocation.csv"))
full_summary_ward <- read.csv(here("03_output","full_rental_summary_byward.csv"))

n_before_calculation <- nrow(full_summary)

#--- Calculations - suburb -----------------------------------------------------
# Add a per night price for tenancy to df
full_summary$median_rent_per_night <- full_summary$Median_rent/7

# Calculate the difference in price between Airbnb and tenancy
full_summary$price_diff_per_night <- abs(full_summary$median_Airbnb_price - full_summary$median_rent_per_night)


#--- Calculations - ward -----------------------------------------------------
# Add a per night price for tenancy to df
full_summary_ward$median_rent_per_night <- full_summary_ward$median_rent/7

# Calculate the difference in price between Airbnb and tenancy
full_summary_ward$price_diff_per_night <- abs(full_summary_ward$median_airbnb_price - full_summary_ward$median_rent_per_night)



# Sanity Check
if (!isTRUE(nrow(full_summary) == n_before_calculation)) {
  stop(
    "11: Adding price calculations changed the number of rows.",
    call. = FALSE
  )
}

if (any(full_summary$price_diff_per_night < 0, na.rm = TRUE)) {
  stop(
    "11: Absolute price differences contain negative values.",
    call. = FALSE
  )
}

# Sanity Check
if (!isTRUE(nrow(full_summary) == n_before_calculation)) {
  stop(
    "11: Adding price calculations changed the number of rows.",
    call. = FALSE
  )
}

if (any(full_summary_ward$price_diff_per_night < 0, na.rm = TRUE)) {
  stop(
    "11: Absolute price differences contain negative values.",
    call. = FALSE
  )
}

# Find the row with the largest difference in price

max_price_diff <- bind_rows(
  full_summary      |> slice_max(price_diff_per_night, n = 1),
  full_summary_ward |> slice_max(price_diff_per_night, n = 1)
)


#--- Output --------------------------------------------------------------
write_csv(full_summary, here("03_output","full_rental_summary_withpricediff.csv"))
write_csv(max_price_diff,here("03_output","maximum_price_difference.csv"))
