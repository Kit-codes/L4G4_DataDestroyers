library(tidyverse)
library(dplyr)

airbnb <- read.csv("~/L4G4_DataDestroyers/output/cleaned/chch_listings_with_area.csv.gz")
rental <- read.csv("~/L4G4_DataDestroyers/output/cleaned/rental_bond_clean.csv.gz")

cleaned_dir   <- file.path("output", "cleaned")
output_file   <- file.path(cleaned_dir, "joined.csv.gz")


joined_data <- full_join(airbnb,rental, by = join_by( year_month == TimeFrame, SA22026_code==Location.Id))


write_csv (joined_data, output_file)

