#--- Plotting Full Data Set ----------------------------------------------------
# Rental vs Airbnb visualisations (saved to 05_plots/)
#   1. Nightly price by ward: Airbnb vs rental
#   2. Nightly price for each SA2 area: Airbnb vs rental
#   3. Number of Airbnb listings and rental bonds by ward
#
# Load Libraries
library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))

#--- Load Data -----------------------------------------------------------------
ward_summary <- read_csv(here("03_output", "full_rental_summary_byward.csv"),
                         show_col_types = FALSE)

sa2_summary <- read_csv(here("03_output", "full_rental_summary_withward.csv"),
                        col_types = cols(SA22026_code = col_character()),
                        show_col_types = FALSE)

# drop the one area with no ward, and convert weekly rent to a nightly price
ward_summary <- ward_summary |>
  filter(!is.na(WARD2023_name)) |>
  mutate(
    rent_per_night = median_rent / 7,
    gap            = median_airbnb_price - rent_per_night
  )

#--- Nightly price by ward: Airbnb vs rental -----------------------------------
# Wards with no rental bond data have no price to compare, so are left out here
no_rent_wards <- ward_summary$WARD2023_name[is.na(ward_summary$rent_per_night)]

ward_prices_long <- ward_summary |>
  filter(!is.na(rent_per_night)) |>
  mutate(WARD2023_name = fct_reorder(WARD2023_name, gap)) |>
  select(WARD2023_name, Airbnb = median_airbnb_price, Rental = rent_per_night) |>
  pivot_longer(c(Airbnb, Rental), names_to = "Type", values_to = "price")

p_ward_prices <- ggplot(ward_prices_long, aes(x = price, y = WARD2023_name, colour = Type)) +
  geom_point() +
  labs(
    title   = "Airbnb vs rental price per night, by ward",
    x       = "Price per night (NZD)",
    y       = "Ward",
    caption = if (length(no_rent_wards) > 0)
      paste("Not shown (no rental bond data):", paste(no_rent_wards, collapse = ", "))
  )
save_plot(p_ward_prices, "13_ward_price_airbnb_vs_rental")

#--- Each SA2 area: Airbnb vs rental nightly price -----------------------------
sa2_prices <- sa2_summary |>
  mutate(rent_per_night = Median_rent / 7) |>
  filter(!is.na(median_Airbnb_price), !is.na(rent_per_night))

p_sa2_prices <- ggplot(sa2_prices, aes(x = rent_per_night, y = median_Airbnb_price)) +
  geom_point() +
  geom_abline(slope = 1, intercept = 0, linetype = "dashed") +
  labs(
    title    = "Airbnb vs rental price per night, by SA2 area",
    subtitle = "Dashed line: both prices equal",
    x        = "Rental price per night (NZD)",
    y        = "Airbnb price per night (NZD)"
  )
save_plot(p_sa2_prices, "13_sa2_price_airbnb_vs_rental")

#--- Airbnb listings and rental bonds by ward ---------------------------------------
ward_counts_long <- ward_summary |>
  select(WARD2023_name,
         `Airbnb listings (all months)` = total_airbnb_properties,
         `Rental bonds`                 = total_rental_bonds) |>
  pivot_longer(-WARD2023_name, names_to = "Type", values_to = "count")

p_ward_counts <- ggplot(ward_counts_long, aes(x = count, y = WARD2023_name)) +
  geom_col() +
  facet_wrap(~ Type, scales = "free_x") +
  labs(
    title = "Airbnb listings and rental bonds by ward",
    x     = "Count",
    y     = "Ward"
  )
save_plot(p_ward_counts, "13_ward_counts_airbnb_vs_rental", width = 10)