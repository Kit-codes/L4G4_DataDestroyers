library(tidyverse)
library(dplyr)

airbnb <- read.csv("~/L4G4_DataDestroyers/output/cleaned/chch_listings_with_area.csv.gz")
rental <- read.csv("~/L4G4_DataDestroyers/output/cleaned/rental_bond_clean.csv.gz")


joined_data <- full_join(airbnb,rental, by = join_by(SA22026_code==Location.Id, year_month == TimeFrame))

