#-------------------------------------------------------------------------------
#Create summary of airbnb dada by location,
#filter tenancy for summary rows
#join the summary tables 

library(tidyverse)
library(dplyr)
library(here)
#-------------------------------------------------------------------------------
#LOAD

airbnb_full <- read_csv(here("3_output","airbnb_chch_cleaned_witharea.csv"))
rental_full <- read_csv(here("3_output","tenancy_chch_cleaned.csv"))
area_codes <- read_csv(here("1_data","geographic_area_table_2026_chch.csv"))

#-------------------------------------------------------------------------------
#summarise airbnb data based on location 
airbnb_summary <- airbnb_full |>
  group_by(SA22026_code) |>
  summarise(
    median_Airbnb_price         = median(price, na.rm = TRUE),
    Number_of_Airbnb_properties = n(),            # listing observations, pooled across snapshots
    Number_of_distinct_listings = n_distinct(id), # unique listing ids
    .groups = "drop"
  )

# sanity check the summary must account for every row in the Airbnb data
check <- sum(airbnb_summary$Number_of_Airbnb_properties)
stopifnot(check == nrow(airbnb_full))

#append the area codes corresponding suburb name
airbnb_summary <- left_join(airbnb_summary, area_codes |> select(SA22026_code, SA22026_name), by = "SA22026_code")

#---------------------------------------------------------------------------------
#  Rental data - filter for ALL, ALL dwelling type and beds = summary rows

rental_filtered <- rental_full |> 
                        filter(`Dwelling Type` == "ALL", `Number Of Beds` == "ALL")

#create summary statistics                      
rental_summary <- rental_filtered |>
  group_by(`Location Id`) |>
  summarise(
    Median_rent = median(`Median Rent`, na.rm = TRUE),
    Number_of_rental_bonds = if (all(is.na(`Total Bonds`))) NA_real_ else max(`Total Bonds`, na.rm = TRUE),
    .groups = "drop"
  )

#---------------------------------------------------------------------------------

# join summarized tables together
full_summary <- full_join(airbnb_summary, rental_summary, by = join_by(SA22026_code==`Location Id`) )

str(full_summary)

#-------------------------------------------------------------------------------
#OUTPUT
write_csv(full_summary, here("3_output","full_rental_summary_bylocation.csv"))




