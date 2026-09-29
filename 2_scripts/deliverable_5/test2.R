library(tidyverse)
library(dplyr)

airbnb <- read.csv("~/L4G4_DataDestroyers/output/cleaned/chch_listings_with_area.csv.gz")
rental <- read.csv("~/L4G4_DataDestroyers/output/cleaned/rental_bond_clean.csv.gz")
area_codes <- read.csv("~/L4G4_DataDestroyers/resource/geographic_area_table_2026_chch.csv")

cleaned_dir   <- file.path("output", "cleaned")
output_file   <- file.path(cleaned_dir, "full_summary.csv.gz")
#------------------------------------------------------------------------------------------
#summarise airbnb data based on loacation 
airbnb_summary <- airbnb |>
                       group_by(SA22026_code) |>
                          summarise (median_Airbnb_price = median(price),
                                     Number_of_Airbnb_properties = table(SA22026_code))   

#check theres still the correct number of properties - should be the same as number of rows in the airbnb dataset
check <- sum(as.numeric(airbnb_summary$Number_of_properties))

#append the area codes corresponding suburb name
airbnb_summary <-   left_join(airbnb_summary, area_codes|> select(SA22026_code,SA22026_name))

#---------------------------------------------------------------------------------
#  Rental data - filter for ALL, ALL dwelling type and beds = summary rows

rental_filtered <- rental|> 
                        filter(Dwelling.Type == "ALL", Number.Of.Beds == "ALL")

#create summary statistics                      
rental_summary <- rental_filtered |>
                    group_by(Location.Id) |>
                              summarise(Median_rent = median(Median.Rent),
                                        Number_of_rental_bonds = max(Total.Bonds))

#---------------------------------------------------------------------------------

# join summarized tables together
full_summary <- full_join(airbnb_summary, rental_summary, by = join_by(SA22026_code==Location.Id) )
write.csv(full_summary, output_file)




