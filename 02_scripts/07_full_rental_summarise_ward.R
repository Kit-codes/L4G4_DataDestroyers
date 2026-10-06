#-------------------------------------------------------------------------------
# Group rental/airbnb summary by ward.

library(tidyverse)
library(here)

#-------------------------------------------------------------------------------
# 1. set paths ------------------------------------------------------------

summary_file      <- here("03_output", "full_rental_summary_withpricediff.csv")
ward_source_file  <- here("01_data", "geographic-areas-table-2023.csv")

lookup_output       <- here("03_output", "full_rental_sa_to_ward_lookup.csv")
withward_output      <- here("03_output", "full_rental_summary_withward.csv")
ward_summary_output <- here("03_output", "full_rental_summary_byward.csv")


# 2. load data --------------------------------------------------------------

full_summary <- read_csv(
  summary_file,
  col_types = cols(SA22026_code = col_character())
)

ward_source <- read_csv(
  ward_source_file,
  col_select = c(SA22023_code, TA2023_name, WARD2023_code, WARD2023_name),
  col_types = cols(.default = col_character())
)


# 3. build an SA -> ward lookup, Christchurch only ----------------------------

ward_counts <- ward_source |>
  filter(TA2023_name == "Christchurch City") |>
  count(SA22023_code, WARD2023_code, WARD2023_name, name = "meshblock_count")

sa2_ward_lookup <- ward_counts |>
  group_by(SA22023_code) |>
  slice_max(meshblock_count, n = 1, with_ties = FALSE) |>
  ungroup() |>
  left_join(
    ward_counts |> count(SA22023_code, name = "n_wards_touched"),
    by = "SA22023_code"
  )


sum(sa2_ward_lookup$n_wards_touched > 1)

write_csv(sa2_ward_lookup, lookup_output)


# 4. attach ward to the SA2 level summary -------------------------------------

full_summary_ward <- full_summary |>
  left_join(
    sa2_ward_lookup |>
      select(SA22023_code, WARD2023_code, WARD2023_name, n_wards_touched),
    by = c("SA22026_code" = "SA22023_code")
  )


sum(is.na(full_summary_ward$WARD2023_name))

write_csv(full_summary_ward, withward_output)


# 5. group by ward ------------------------------------------------------------

ward_summary <- full_summary_ward |>
  group_by(WARD2023_name) |>
  summarise(
    n_SA2_areas             = n(),
    total_airbnb_properties = sum(Number_of_Airbnb_properties, na.rm = TRUE),
    median_airbnb_price     = median(median_Airbnb_price, na.rm = TRUE),
    total_rental_bonds      = sum(Number_of_rental_bonds, na.rm = TRUE),
    median_rent             = median(Median_rent, na.rm = TRUE),
    .groups = "drop"
  ) |>
  arrange(desc(total_airbnb_properties))

print(ward_summary, n = Inf)


# 6. save ----------------------------------------------------------------------

write_csv(ward_summary, ward_summary_output)

cat("\nSaved ward-level summary to:\n", ward_summary_output, "\n")

str(ward_summary
  )
