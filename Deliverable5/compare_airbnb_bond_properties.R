# 1. install packages, uncomment if needed -----------------------------------

# install.packages("tidyverse")


# 2. load packages ------------------------------------------------------------

library(tidyverse)


# 3. setup paths ---------------------------------------------------------

airbnb_file <- file.path(
  "output",
  "cleaned",
  "chch_listings_with_area.csv.gz"
)

bond_file <- file.path(
  "output",
  "cleaned",
  "rental_bond_clean.csv.gz"
)

area_lookup_file <- file.path(
  "output",
  "cleaned",
  "area_code_lookup.csv"
)

output_file <- file.path(
  "output",
  "cleaned",
  "airbnb_rental_properties_count_by_location.csv"
)


# 4. load data -----------------------------------------------------------

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


# 5. count Airbnb listings by SA2 ---------------------------------------

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


# 6. get rental bond count by SA2 ----------------------------------

rental_count <- bond |>
  filter(
    TimeFrame == "2026/04/01",   # use the latest: 2026-04-01
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


# 8. replace missing counts with 0 --------------------------------------

location_counts <- location_counts |>
  mutate(
    airbnb_count = replace_na(airbnb_count, 0),
    rental_count = replace_na(rental_count, 0)
  )


# 9. calculate difference ------------------------------------------------

location_counts <- location_counts |>
  mutate(
    count_difference = airbnb_count - rental_count
  )

names(area_lookup)

# 10. add area name and sort result --------------------------------------

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


# 11. inspect results ----------------------------------------------------

print(location_counts)


# 12. summary checks -----------------------------------------------------

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


# 13. save results -------------------------------------------------------

write_csv(
  location_counts,
  output_file
)

cat(
  "\nSaved comparison to:\n",
  output_file,
  "\n"
)
















