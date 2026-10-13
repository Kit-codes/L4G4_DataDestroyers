 #--- AirBnb Christchurch Visualisation -----------------------------------------
#Description: Creates plots for  Airbnb Data - pre-cleaning
#             1.New Zealand price distribution
#             2.Christchurch price distribution
#             3.Price distribution comparison, New Zealand and Christchurch
#             4.Add days since days since last review column, plot days since last review
#             5. Calculate top 10 percent of reviews


# Inputs: airbnb_chch_preprocessed.csv - csv file containing preprocessed Airbnb data
#         airbnb_nz_preprocessed.csv - csv file containing preprocessed Airbnb data       

# Outputs: 09_price_distribution_chch.png
#          09_price_distribution_nz_vs_chch.png
#          09_price_distribution_nz_vs_chch.png
#          09_days_since_last_review.png

#--- Load libraries ------------------------------------------------------------


library(tidyverse)
library(here)
source(here("02_scripts", "00_tools", "config.R"))
source(here("02_scripts","00_tools","topPercent.R"))
cfg <- get_config()

#--- Load Data -----------------------------------------------------------------
nz_data <- read_csv(here("03_output", "airbnb_nz_preprocessed.csv"))
chch_data <- read_csv(here("03_output", "airbnb_chch_preprocessed.csv"))

#--- Original and updated datasets ---------------------------------------------

periods <- comparison_periods(nz_data, cfg)

nz_compare <- comparison_rows(nz_data, periods)
chch_compare <- comparison_rows(chch_data, periods)

version_colours <- setNames(
  c("#0072B2", "#D55E00"),
  c(periods$old_label, periods$new_label)
)

#--- New Zealand price distribution --------------------------------------------

p_price_nz <- ggplot(
  nz_compare,
  aes(x = price, fill = Version, colour = Version)
) +
  geom_histogram(
    binwidth = 20,
    boundary = 0,
    position = "identity",
    alpha = 0.35,
    na.rm = TRUE
  ) +
  scale_fill_manual(values = version_colours) +
  scale_colour_manual(values = version_colours) +
  coord_cartesian(xlim = c(0, 5000)) +
  labs(
    title = "New Zealand Airbnb prices: original vs updated",
    x = "Price (NZD)",
    y = "Count",
    fill = "Data period",
    colour = "Data period"
  )

save_plot(p_price_nz, "09_price_distribution_nz")

#--- Christchurch price distribution -------------------------------------------

p_price_chch <- ggplot(
  chch_compare,
  aes(x = price, fill = Version, colour = Version)
) +
  geom_histogram(
    binwidth = 10,
    boundary = 0,
    position = "identity",
    alpha = 0.35,
    na.rm = TRUE
  ) +
  scale_fill_manual(values = version_colours) +
  scale_colour_manual(values = version_colours) +
  coord_cartesian(xlim = c(0, 2000)) +
  labs(
    title = paste(cfg$area, "Airbnb prices: original vs updated"),
    x = "Price (NZD)",
    y = "Count",
    fill = "Data period",
    colour = "Data period"
  )

save_plot(p_price_chch, "09_price_distribution_chch")

#--- New Zealand vs Christchurch ------------------------------------------------
# One panel per area, with original and updated shown in each panel.

price_comparison <- bind_rows(
  nz_compare |> mutate(Area = "All New Zealand"),
  chch_compare |> mutate(Area = cfg$area)
)

p_price_comparison <- ggplot(
  price_comparison,
  aes(x = price, fill = Version, colour = Version)
) +
  geom_histogram(
    binwidth = 25,
    boundary = 0,
    position = "identity",
    alpha = 0.35,
    na.rm = TRUE
  ) +
  facet_wrap(~ Area, ncol = 1) +
  scale_fill_manual(values = version_colours) +
  scale_colour_manual(values = version_colours) +
  coord_cartesian(xlim = c(0, 1000)) +
  labs(
    title = "Airbnb prices: New Zealand vs Christchurch",
    x = "Price (NZD)",
    y = "Count",
    fill = "Data period",
    colour = "Data period"
  )

save_plot(
  p_price_comparison,
  "09_price_distribution_nz_vs_chch",
  height = 8
)

#--- Days since last review ----------------------------------------------------

baseline_date <- if (is.null(cfg$collection_date)) {
  month_end(periods$baseline)
} else {
  as.Date(as.character(cfg$collection_date))
}

updated_date <- get_collection_date()

if (length(baseline_date) != 1 ||
    is.na(baseline_date) ||
    is.na(updated_date)) {
  stop("Invalid review comparison date.", call. = FALSE)
}

review_comparison <- chch_compare |>
  mutate(
    last_review = as.Date(last_review),
    reference_date = if_else(
      Version == periods$old_label,
      baseline_date,
      updated_date
    ),
    days_since_last_review = as.numeric(reference_date - last_review)
  )

if (any(review_comparison$days_since_last_review < 0, na.rm = TRUE)) {
  stop(
    "A review date is later than its comparison reference date.",
    call. = FALSE
  )
}

p_days_since_review <- ggplot(
  review_comparison,
  aes(x = days_since_last_review, fill = Version, colour = Version)
) +
  geom_histogram(
    binwidth = 5,
    boundary = 0,
    position = "identity",
    alpha = 0.35,
    na.rm = TRUE
  ) +
  scale_fill_manual(values = version_colours) +
  scale_colour_manual(values = version_colours) +
  coord_cartesian(xlim = c(-10, 1000)) +
  labs(
    title = "Days since last review: original vs updated",
    subtitle = paste(
      "Original reference:", baseline_date,
      "| Updated reference:", updated_date
    ),
    x = "Days since last review",
    y = "Count",
    fill = "Data period",
    colour = "Data period"
  )

save_plot(p_days_since_review, "09_days_since_last_review")

#--- Calculate top 10% number of reviews ---------------------------------------
top_10_reviews <- topPercent(nz_data, nz_data$number_of_reviews, 0.1 )

# Sanity Check
if (!isTRUE(
  nrow(top_10_reviews) == floor(nrow(nz_data) * 0.1)
)) {
  stop(
    "09: The top-10-percent selection has an unexpected row count.",
    call. = FALSE
  )
}

top_10_reviews |>
  summarise(
    total_top_10 = n(),
    christchurch_count = sum(
      neighbourhood_group == cfg$area,
      na.rm = TRUE
    )
  )
