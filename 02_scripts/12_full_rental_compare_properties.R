#--- Compare Full Data Set -----------------------------------------------------
# Compare the number of beds per location airbnb vs tenancy
#
# Load Libraries
library(tidyverse)
library(here)

#--- Load Data -----------------------------------------------------------------
airbnb_file <- here("03_output","airbnb_chch_cleaned_witharea.csv")

bond_file <- here("03_output","tenancy_chch_cleaned.csv")
area_lookup_file <- here("0_output", "area_code_lookup.csv")
output_file <- here("03_output","airbnb_rental_properties_count_by_location.csv")

airbnb <- read_csv(
  airbnb_file,
  col_types = cols(
    id = col_character(),
    host_id = col_character(),
    SA22026_code = col_character()
  )
)

bond <- read_csv(
  bond_file,
  col_types = cols(
    `Location Id` = col_character()
  )
)

area_lookup <- read_csv(
  area_lookup_file,
  col_types = cols(
    SA22026_code = col_character()
  )
)

#--- Count Airbnb Listings by SA2 Code -----------------------------------------
airbnb_count <- airbnb |>
  filter(
    year_month == "2026_06"  # use the latest: 2026-06
  ) |>
  group_by(
    SA22026_code
  ) |>
  summarise(
    airbnb_count = n_distinct(id),  # use id to be identical
    .groups = "drop"
  )

#--- Get rental bond count by SA2 ----------------------------------------------
rental_count <- bond |>
  filter(
    TimeFrame == "2026-04-01",   # use the latest: 2026-04-01
    `Dwelling Type` == "ALL",    # only use ALL type 
    `Number Of Beds` == "ALL"    # only use ALL type
  ) |>
  transmute(
    SA22026_code = `Location Id`,
    rental_count = `Active Bonds`    # use active bond, not total
  )


# 7. join the two summary tables ----------------------------------------

location_counts <- full_join(
  airbnb_count,
  rental_count,
  by = "SA22026_code"
)

#--- Replace missing counts with 0 ---------------------------------------------
location_counts <- location_counts |>
  mutate(
    airbnb_count = replace_na(airbnb_count, 0),
    rental_count = replace_na(rental_count, 0)
  )


#--- Calculate differences -----------------------------------------------------
location_counts <- location_counts |>
  mutate(
    count_difference = airbnb_count - rental_count
  )

names(area_lookup)

#--- Add area name and sort results --------------------------------------------
location_counts <- location_counts |>
  left_join(
    area_lookup |>
      select(
        SA22026_code,
        SA22026_name
      ) |>
      distinct(),
    by = "SA22026_code"
  ) |>
  relocate(
    SA22026_name,
    .after = SA22026_code
  ) |>
  arrange(SA22026_code)

#--- Checks --------------------------------------------------------------------
cat(
  "\nNumber of SA2 areas:",
  nrow(location_counts),
  "\n"
)

cat(
  "Total Airbnb listings:",
  sum(location_counts$airbnb_count),
  "\n"
)

cat(
  "Total active rental bonds:",
  sum(location_counts$rental_count),
  "\n"
)


#--- Output --------------------------------------------------------------------
write_csv(
  location_counts,
  output_file
)

cat(
  "\nSaved comparison to:\n",
  output_file,
  "\n"
)
















