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
#summarise airbnb data based on loacation 
airbnb_summary <- airbnb_full |>
                       group_by(SA22026_code) |>
                          summarise (median_Airbnb_price = median(price),
                                     Number_of_Airbnb_properties = table(SA22026_code)[1])   

#check theres still the correct number of properties - should be the same as number of rows in the airbnb dataset
check <- sum(as.numeric(airbnb_summary$Number_of_Airbnb_properties))== nrow(airbnb_full)
check

#append the area codes corresponding suburb name
airbnb_summary <-   left_join(airbnb_summary, area_codes|> select(SA22026_code,SA22026_name))

#---------------------------------------------------------------------------------
#  Rental data - filter for ALL, ALL dwelling type and beds = summary rows

rental_filtered <- rental_full |> 
                        filter(`Dwelling Type` == "ALL", `Number Of Beds` == "ALL")

#create summary statistics                      
rental_summary <- rental_filtered |>
                    group_by(`Location Id`) |>
                              summarise(Median_rent = median(`Median Rent`),
                                        Number_of_rental_bonds = max(`Total Bonds`))

#---------------------------------------------------------------------------------

# join summarized tables together
full_summary <- full_join(airbnb_summary, rental_summary, by = join_by(SA22026_code==`Location Id`) )

str(full_summary)

#-------------------------------------------------------------------------------
#OUTPUT
write_csv(full_summary, here("3_output","full_rental_summary_bylocation.csv"))




