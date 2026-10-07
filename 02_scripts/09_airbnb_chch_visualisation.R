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

#--- Price Plot ----------------------------------------------------------------
p_price_nz <- ggplot(nz_data, aes(x = price)) +
  geom_histogram(binwidth = 20) +
  coord_cartesian(xlim = c(0, 5000)) + # 0-5000 span
  labs(
    title = "Distribution of Airbnb Prices in New Zealand",
    x = "Price",
    y = "Count"
  )
save_plot(p_price_nz, "09_price_distribution_nz")

p_price_chch <- ggplot(chch_data, aes(x = price)) +
  geom_histogram(binwidth = 10) +
  coord_cartesian(xlim = c(0, 2000)) + # 0-2000 span
  labs(
    title = paste("Distribution of Airbnb Prices in", cfg$area),
    x = "Price",
    y = "Count"
  )
save_plot(p_price_chch, "09_price_distribution_chch")

#--- Merge Plots ---------------------------------------------------------------
price_comparison <- bind_rows(
  nz_data |>
    mutate(area = "All New Zealand"),
  
  chch_data|>
    mutate(area = cfg$area)
)

# Sanity Check
if (!isTRUE(
  nrow(price_comparison) == nrow(nz_data) + nrow(chch_data)
)) {
  stop(
    "09: Combined price plot data has an unexpected row count.",
    call. = FALSE
  )
}

p_price_comparison <- ggplot(
  price_comparison,
  aes(
    x = price,
    fill = area
  )
) +
  geom_histogram(
    binwidth = 25,
    position = "identity",
    alpha = 0.5
  ) +
  coord_cartesian(
    xlim = c(0, 1000)
  ) +
  labs(
    title = paste("Airbnb Price Distribution: New Zealand vs", cfg$area),
    x = "Price (NZD)",
    y = "Count",
    fill = "Area"
  )
save_plot(p_price_comparison, "09_price_distribution_nz_vs_chch")

#--- Days Since Last Review ----------------------------------------------------
# Calculate the day since last review use latest snapshot date 
# (see get_collection_date() in pipeline_helpers.R)
airbnb_collection_date <- get_collection_date()

chch_data <- chch_data |>
  mutate(
    last_review = as.Date(last_review),
    days_since_last_review = as.numeric(
      airbnb_collection_date  - last_review
    )
  )

# Sanity Check
if (any(chch_data$days_since_last_review < 0, na.rm = TRUE)) {
  stop(
    "09: A last-review date is later than the collection date. ",
    "Check the review dates and collection date.",
    call. = FALSE
  )
}

#--- Days Since Last Review Plot ----------------------------------------------------
p_days_since_review <- ggplot(
  chch_data,
  aes(x = days_since_last_review)
) +
  coord_cartesian(xlim = c(-10, 1000)) +
  geom_histogram(
    binwidth = 5,
    na.rm = TRUE
  ) +
  labs(
    title = "Distribution of Days Since Last Review",
    x = "Days Since Last Review",
    y = "Count"
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
