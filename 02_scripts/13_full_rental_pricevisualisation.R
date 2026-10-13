#--- Plotting Full Data Set ----------------------------------------------------
# Description: Rental vs Airbnb visualisations (saved to 05_plots/)
#              1. Nightly price by ward: Airbnb vs rental
#              2. Nightly price for each SA2 area: Airbnb vs rental
#              3. Number of Airbnb listings and rental bonds by ward

# Inputs: full_rental_summary_byward - Airbnb and tenancy data by location (ward level)
#         full_rental_summary_withward.csv - Airbnb and tenancy data by location (suburb level) with ward column
# Outputs: 12_ward_price_airbnb_vs_rental.png
#          12_sa2_price_airbnb_vs_rental.png
#          12_ward_counts_airbnb_vs_rental.png

#--- Original Airbnb vs updated Airbnb vs rental -------------------------------

library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))
cfg <- get_config()

#--- Read data -----------------------------------------------------------------

airbnb <- read_csv(
  here("03_output", "airbnb_chch_cleaned_witharea.csv"),
  col_types = cols(
    id = col_character(),
    SA22026_code = col_character()
  ),
  show_col_types = FALSE
)

bond <- read_csv(
  here("03_output", "tenancy_chch_cleaned.csv"),
  col_types = cols(
    `Location Id` = col_character(),
    TimeFrame = col_date()
  ),
  show_col_types = FALSE
)

ward_lookup <- read_csv(
  here("03_output", "full_rental_sa_to_ward_lookup.csv"),
  col_types = cols(SA22023_code = col_character()),
  show_col_types = FALSE
) |>
  transmute(
    SA22026_code = SA22023_code,
    WARD2023_name
  )

if (anyDuplicated(ward_lookup$SA22026_code) > 0) {
  stop("The ward lookup contains duplicate SA2 codes.", call. = FALSE)
}

# Use raw month availability to define the periods.
periods <- comparison_periods(get_airbnb_months(), cfg)

airbnb_compare <- comparison_rows(airbnb, periods)

version_colours <- setNames(
  c("#0072B2", "#D55E00"),
  c(periods$old_label, periods$new_label)
)

#--- Fixed rental reference ----------------------------------------------------
# Keep rental data within the original Airbnb period.

bond_reference <- bond |>
  filter(
    TimeFrame >= month_start(periods$first),
    TimeFrame <= month_end(periods$baseline),
    `Dwelling Type` == cfg$dwelling_type,
    `Number Of Beds` == cfg$number_of_beds
  )

if (nrow(bond_reference) == 0 || anyNA(bond_reference$TimeFrame)) {
  stop("No valid rental reference period is available.", call. = FALSE)
}

reference_quarter <- max(bond_reference$TimeFrame)

rental_prices <- bond_reference |>
  group_by(SA22026_code = `Location Id`) |>
  summarise(
    rent_per_night = median(`Median Rent`) / 7,
    .groups = "drop"
  )

rental_counts <- bond_reference |>
  filter(TimeFrame == reference_quarter) |>
  transmute(
    SA22026_code = `Location Id`,
    rental_count = `Active Bonds`
  )

if (anyDuplicated(rental_counts$SA22026_code) > 0) {
  stop("Rental reference has duplicate SA2 rows.", call. = FALSE)
}

#--- Airbnb prices by SA2 -------------------------------------------------------

airbnb_prices <- airbnb_compare |>
  filter(!is.na(SA22026_code)) |>
  group_by(Version, SA22026_code) |>
  summarise(
    airbnb_price = median(price),
    .groups = "drop"
  )

#--- Ward prices: three groups -------------------------------------------------

ward_airbnb_prices <- airbnb_prices |>
  left_join(ward_lookup, by = "SA22026_code") |>
  filter(!is.na(WARD2023_name)) |>
  group_by(Version, WARD2023_name) |>
  summarise(
    price = median(airbnb_price, na.rm = TRUE),
    .groups = "drop"
  ) |>
  mutate(Type = as.character(Version)) |>
  select(WARD2023_name, Type, price)

# Same SA2 domain for the rental reference in both Airbnb comparisons.
ward_rental_prices <- rental_prices |>
  semi_join(
    distinct(airbnb_prices, SA22026_code),
    by = "SA22026_code"
  ) |>
  left_join(ward_lookup, by = "SA22026_code") |>
  filter(!is.na(WARD2023_name)) |>
  group_by(WARD2023_name) |>
  summarise(
    price = if (all(is.na(rent_per_night))) {
      NA_real_
    } else {
      median(rent_per_night, na.rm = TRUE)
    },
    .groups = "drop"
  ) |>
  mutate(Type = "Rental")

ward_prices_long <- bind_rows(
  ward_airbnb_prices,
  ward_rental_prices
)

p_ward_prices <- ggplot(
  ward_prices_long,
  aes(x = price, y = WARD2023_name, colour = Type, shape = Type)
) +
  geom_point(size = 2.5, na.rm = TRUE) +
  scale_colour_manual(
    values = c(version_colours, Rental = "#009E73")
  ) +
  labs(
    title = "Airbnb and rental prices by ward",
    subtitle = "Rental reference is fixed to the original period",
    x = "Price per night (NZD)",
    y = "Ward"
  )

save_plot(p_ward_prices, "13_ward_price_airbnb_vs_rental")

#--- SA2 scatter plot: two Airbnb points per area -------------------------------
# Rental is represented by the x coordinate.

sa2_prices <- airbnb_prices |>
  left_join(rental_prices, by = "SA22026_code") |>
  filter(!is.na(airbnb_price), !is.na(rent_per_night))

if (nrow(sa2_prices) == 0) {
  stop("No SA2 prices are available for comparison.", call. = FALSE)
}

p_sa2_prices <- ggplot(
  sa2_prices,
  aes(
    x = rent_per_night,
    y = airbnb_price,
    colour = Version,
    shape = Version
  )
) +
  geom_point(alpha = 0.7, size = 2) +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  scale_colour_manual(values = version_colours) +
  labs(
    title = "Original and updated Airbnb prices by SA2",
    x = "Rental price per night (NZD)",
    y = "Airbnb price per night (NZD)",
    colour = "Data period",
    shape = "Data period"
  )

save_plot(p_sa2_prices, "13_sa2_price_airbnb_vs_rental")

#--- Latest-month Airbnb counts ------------------------------------------------

airbnb_snapshot_counts <- airbnb |>
  filter(year_month %in% c(periods$baseline, periods$latest)) |>
  left_join(ward_lookup, by = "SA22026_code") |>
  filter(!is.na(WARD2023_name)) |>
  group_by(year_month, WARD2023_name) |>
  summarise(
    count = n_distinct(id),
    .groups = "drop"
  )

# Ward universe includes both Airbnb snapshots and rental data.
ward_names <- ward_lookup |>
  filter(!is.na(WARD2023_name)) |>
  distinct(WARD2023_name)

old_counts <- ward_names |>
  left_join(
    airbnb_snapshot_counts |>
      filter(year_month == periods$baseline) |>
      select(WARD2023_name, count),
    by = "WARD2023_name"
  ) |>
  mutate(
    count = replace_na(count, 0L),
    Type = paste("Original Airbnb:", periods$baseline)
  )

new_counts <- ward_names |>
  left_join(
    airbnb_snapshot_counts |>
      filter(year_month == periods$latest) |>
      select(WARD2023_name, count),
    by = "WARD2023_name"
  ) |>
  mutate(
    count = replace_na(count, 0L),
    Type = paste("Updated Airbnb:", periods$latest)
  )

ward_rental_counts <- rental_counts |>
  left_join(ward_lookup, by = "SA22026_code") |>
  filter(!is.na(WARD2023_name)) |>
  group_by(WARD2023_name) |>
  summarise(
    # Keep unknown totals as NA rather than treating them as zero.
    count = sum(rental_count),
    .groups = "drop"
  ) |>
  mutate(Type = paste("Rental:", reference_quarter))

ward_counts_long <- bind_rows(
  old_counts,
  new_counts,
  ward_rental_counts
)

p_ward_counts <- ggplot(
  ward_counts_long,
  aes(x = count, y = WARD2023_name)
) +
  geom_col(na.rm = TRUE) +
  facet_wrap(~ Type, nrow = 1, scales = "free_x") +
  labs(
    title = "Original Airbnb, updated Airbnb and active rental bonds",
    subtitle = "Areas without a ward are excluded",
    x = "Count",
    y = "Ward"
  )

save_plot(
  p_ward_counts,
  "13_ward_counts_airbnb_vs_rental",
  width = 14
)

# Save the comparison data behind these plots.
write_csv(
  ward_prices_long,
  here("03_output", "comparison_ward_prices.csv")
)

write_csv(
  sa2_prices,
  here("03_output", "comparison_sa2_prices.csv")
)

write_csv(
  ward_counts_long,
  here("03_output", "comparison_ward_counts.csv")
)
