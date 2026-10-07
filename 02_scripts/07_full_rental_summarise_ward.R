#--- Group rental/airbnb summary by ward ---------------------------------------

#Description: Creates a summary dataset for airbnb and tenancy data based on location at ward level


# Inputs: full_rental_summary_bylocation - csv file containing summary dataset with rental and airbnb data for each location (suburb level)
#         geographic-areas-table-2023.csv  - datset containing data relating to geographic locations, including area codes, wards

# Outputs: full_rental_summary_withward - csv file containing summary dataset with rental and airbnb data for each location (ward level)

#--- Load libraries ------------------------------------------------------------
# Load Libraries
library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))
cfg <- get_config()

#--- Load Data -----------------------------------------------------------------
summary_file <- here("03_output", "full_rental_summary_bylocation.csv")
ward_source_file <- here("01_data", "geographic-areas-table-2023.csv")
lookup_output <- here("03_output", "full_rental_sa_to_ward_lookup.csv")
withward_output <- here("03_output", "full_rental_summary_withward.csv")
ward_summary_output <- here("03_output", "full_rental_summary_byward.csv")

full_summary <- read_csv(
  summary_file,
  col_types = cols(SA22026_code = col_character())
)

ward_source <- read_csv(
  ward_source_file,
  col_select = c(SA22023_code, TA2023_name, WARD2023_code, WARD2023_name),
  col_types = cols(.default = col_character())
)

#--- Ward Lookup ---------------------------------------------------------------
# Build an SA
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

# Sanity Check
if (anyDuplicated(sa2_ward_lookup$SA22023_code) > 0) {
  stop(
    "07: The selected ward lookup contains more than one row per SA2.",
    call. = FALSE
  )
}

sum(sa2_ward_lookup$n_wards_touched > 1)

write_csv(sa2_ward_lookup, lookup_output)

#--- Attach Ward ---------------------------------------------------------------
# Attach to SA2
full_summary_ward <- full_summary |>
  left_join(
    sa2_ward_lookup |>
      select(SA22023_code, WARD2023_code, WARD2023_name, n_wards_touched),
    by = c("SA22026_code" = "SA22023_code")
  )

# Sanity Check
if (!isTRUE(nrow(full_summary_ward) == nrow(full_summary))) {
  stop(
    "07: Adding ward information changed the number of summary rows.",
    call. = FALSE
  )
}


sum(is.na(full_summary_ward$WARD2023_name))

write_csv(full_summary_ward, withward_output)

#--- Group by Ward -------------------------------------------------------------
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

# Sanity Check
if (!isTRUE(
  sum(ward_summary$total_airbnb_properties, na.rm = TRUE) ==
  sum(full_summary_ward$Number_of_Airbnb_properties, na.rm = TRUE)
)) {
  stop(
    "07: Airbnb counts changed after grouping by ward.",
    call. = FALSE
  )
}

if (!isTRUE(
  sum(ward_summary$total_rental_bonds, na.rm = TRUE) ==
  sum(full_summary_ward$Number_of_rental_bonds, na.rm = TRUE)
)) {
  stop(
    "07: Rental bond counts changed after grouping by ward.",
    call. = FALSE
  )
}

if (!isTRUE(
  sum(ward_summary$n_SA2_areas) == nrow(full_summary_ward)
)) {
  stop(
    "07: The SA2 row count changed after grouping by ward.",
    call. = FALSE
  )
}

print(ward_summary, n = Inf)

#--- Output --------------------------------------------------------------------
write_csv(ward_summary, ward_summary_output)

cat("\nSaved ward-level summary to:\n", ward_summary_output, "\n")
str(ward_summary)