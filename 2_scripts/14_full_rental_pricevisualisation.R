#-------------------------------------------------------------------------------
# Visualise nightly Airbnb price vs long-term rental price by ward.
# Reads the ward summary made by 12_full_rental_grouping.R.

library(tidyverse)
library(here)

#-------------------------------------------------------------------------------
# LOAD DATA
area_with_ward <- read_csv(here("3_output", "full_rental_summary_byward.csv"),
                           show_col_types = FALSE)

area_with_ward <- area_with_ward |>
  mutate(
    median_rent_night = median_rent / 7,
    price_diff        = median_airbnb_price - median_rent_night
  )

not_plottable <- area_with_ward |>
  filter(is.na(WARD2023_name) | is.na(median_airbnb_price) | is.na(median_rent_night))

if (nrow(not_plottable) > 0) {
  message(
    nrow(not_plottable), " row(s) left out of the plots",
    paste(coalesce(not_plottable$WARD2023_name, "no ward"), collapse = ", ")
  )
}

plot_data <- area_with_ward |>
  filter(!is.na(WARD2023_name), !is.na(median_airbnb_price), !is.na(median_rent_night))

plot_caption <- paste(
  "Airbnb: median of SA2 medians, all room types, pooled snapshots.",
  "Rent: median weekly rent / 7.",
  sep = "\n"
)

#-------------------------------------------------------------------------------
# PLOT 1: distribution of ward-level nightly prices, Airbnb vs rental
price_long <- plot_data |>
  pivot_longer(
    cols = c(median_airbnb_price, median_rent_night),
    names_to = "Type",
    values_to = "Price per night"
  ) |>
  mutate(
    Type = recode(
      Type,
      median_airbnb_price = "Airbnb (per night)",
      median_rent_night   = "Long-term rent (weekly / 7)"
    )
  )

price_plot <- ggplot(price_long, aes(x = `Price per night`, fill = Type)) +
  geom_histogram(binwidth = 10, position = "identity", alpha = 0.5) +
  coord_cartesian(xlim = c(0, 300)) +
  labs(
    title    = "Nightly Price Distribution Across Wards: Rental vs Airbnb",
    x        = "Price per night (NZD)",
    y        = "Number of wards",
    fill     = NULL
  )

print(price_plot)

#-------------------------------------------------------------------------------
# PLOT 2: Airbnb premium over long-term rent, by ward
price_plot2 <- ggplot(plot_data,
                      aes(x = reorder(WARD2023_name, price_diff), y = price_diff)) +
  geom_col() +
  coord_flip() +
  labs(
    title   = "Airbnb Nightly Price Minus Rental Nightly Price, by Ward",
    x       = NULL,
    y       = "Difference per night (NZD)"
  )

print(price_plot2)

#-------------------------------------------------------------------------------
# OUTPUT
plots_dir <- here("3_output", "plots")
dir.create(plots_dir, showWarnings = FALSE, recursive = TRUE)

ggsave(file.path(plots_dir, "ward_price_distribution.png"), price_plot,
       width = 9, height = 6, dpi = 150)
ggsave(file.path(plots_dir, "ward_price_difference.png"), price_plot2,
       width = 9, height = 6, dpi = 150)