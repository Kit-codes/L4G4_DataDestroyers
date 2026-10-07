#--- Compare Full Data Set -----------------------------------------------------
# Decription: Compare the number of beds per location airbnb vs tenancy

#Inputs: airbnb_chch_cleaned_witharea.csv - csv file containing cleaned airbnb data with area codes
#        tenancy_chch_cleaned.csv - csv file containing cleaned tenancy data

# Outputs:airbnb_rental_properties_count_by_location.csv - csv file containing bed counts for tenancy and airbnb, by location
#
#--- Load libraries ------------------------------------------------------------
library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))
cfg <- get_config()

#--- Load Data -----------------------------------------------------------------
airbnb_file <- here("03_output","airbnb_chch_cleaned_witharea.csv")

bond_file <- here("03_output","tenancy_chch_cleaned.csv")
area_lookup_file <- here("03_output", "area_code_lookup.csv")
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

#--- Calculate comparison ------------------------------------------------------
# latest Airbnb snapshot, and latest tenancy quarter in the (windowed) bond data
latest_month   <- latest_airbnb_month()
latest_quarter <- max(bond$TimeFrame)
message("Comparing Airbnb ", latest_month, " with tenancy quarter ", latest_quarter)

#--- Count Airbnb Listings by SA2 Code -----------------------------------------
airbnb_count <- airbnb |>
  filter(
    year_month == latest_month
  ) |>
  group_by(
    SA22026_code
  ) |>
  summarise(
    airbnb_count = n_distinct(id),  # use id to be identical
    .groups = "drop"
  )

# Sanity Check
expected_airbnb_count <- airbnb |>
  filter(year_month == latest_month) |>
  summarise(count = n_distinct(id)) |>
  pull(count)

if (!isTRUE(
  sum(airbnb_count$airbnb_count) == expected_airbnb_count
)) {
  stop(
    "12: Summarised Airbnb counts do not match distinct IDs in the latest month.",
    call. = FALSE
  )
}

#--- Get rental bond count by SA2 ----------------------------------------------
rental_count <- bond |>
  filter(
    TimeFrame == latest_quarter, # the latest quarter
    `Dwelling Type` == cfg$dwelling_type, # summary rows (set in config.yaml)
    `Number Of Beds` == cfg$number_of_beds
  ) |>
  transmute(
    SA22026_code = `Location Id`,
    rental_count = `Active Bonds`
  )

# Sanity Check
if (anyDuplicated(rental_count$SA22026_code) > 0) {
  stop(
    "12: The rental count table contains duplicate SA2 codes.",
    call. = FALSE
  )
}

#--- Join the two summary tables -----------------------------------------------

location_counts <- full_join(
  airbnb_count,
  rental_count,
  by = "SA22026_code"
)

# Sanity Check
if (!isTRUE(
  sum(location_counts$airbnb_count, na.rm = TRUE) ==
  sum(airbnb_count$airbnb_count, na.rm = TRUE)
)) {
  stop(
    "12: Joining count tables changed the Airbnb total.",
    call. = FALSE
  )
}

if (!isTRUE(
  sum(location_counts$rental_count, na.rm = TRUE) ==
  sum(rental_count$rental_count, na.rm = TRUE)
)) {
  stop(
    "12: Joining count tables changed the rental bond total.",
    call. = FALSE
  )
}

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
n_before_name_join <- nrow(location_counts)

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
if (!isTRUE(nrow(location_counts) == n_before_name_join)) {
  stop(
    "12: Adding area names changed the number of location rows.",
    call. = FALSE
  )
}

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