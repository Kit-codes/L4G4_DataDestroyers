#--- Summary of Airbnb Data by Location ----------------------------------------
#Description: Creates a summary dataset for airbnb and tenancy data based on location
#             Summarises airbnb data set based on location, with median prices for the location
#             Filter tenancy data for summary rows
#             Join the summary tables  


# Inputs: airbnb_chch_cleaned_witharea - csv file containing cleaned Airbnb data with area codes
#         tenancy_chch_cleaned - csv file containing cleaned tenancy data

# Outputs: full_rental_summary_bylocation.csv - csv file containing summary dataset with rental and airbnb data for each location 


#--- Load libraries ------------------------------------------------------------
# Load libraries
library(tidyverse)
library(dplyr)
library(here)
source(here("02_scripts", "00_tools", "config.R"))
cfg <- get_config()

#--- Load Data -----------------------------------------------------------------
airbnb_full <- read_csv(here("03_output","airbnb_chch_cleaned_witharea.csv"))
rental_full <- read_csv(here("03_output","tenancy_chch_cleaned.csv"))
area_codes <- read_csv(here("01_data","geographic_area_table_2026_chch.csv"))

#--- Summarise Airbnb Data Based on Location ----------------------------------
airbnb_summary <- airbnb_full |>
                       group_by(SA22026_code) |>
                          summarise (median_Airbnb_price = median(price),
                                     Number_of_Airbnb_properties = table(SA22026_code)[1])   

#--- Sanity Check --------------------------------------------------------------
# Check there is still the correct number of properties, there should be the 
# Same amount as the number of rows in the Airbnb dataset.
check <- sum(as.numeric(airbnb_summary$Number_of_Airbnb_properties))== nrow(airbnb_full)
check

# Append the area codes corresponding suburb name
airbnb_summary <- left_join(airbnb_summary,
                            area_codes|> select(SA22026_code,SA22026_name))

#--- Filter Rental Data --------------------------------------------------------
# Filter for ALL, ALL dwelling type and beds = summary rows
rental_filtered <- rental_full |> 
  filter(`Dwelling Type` == cfg$dwelling_type,
         `Number Of Beds` == cfg$number_of_beds)

#--- Create Summary Statistics -------------------------------------------------
rental_summary <- rental_filtered |>
  group_by(`Location Id`) |>
  summarise(Median_rent = median(`Median Rent`),
            Number_of_rental_bonds = max(`Total Bonds`))

#--- Join summarised tables together -------------------------------------------
full_summary <- left_join(airbnb_summary, rental_summary, 
                          by = join_by(SA22026_code==`Location Id`) )
str(full_summary)

#--- Output --------------------------------------------------------------------
write_csv(full_summary, here("03_output","full_rental_summary_bylocation.csv"))

