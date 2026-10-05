#-------------------------------------------------------------------------------
#AirBnB Christchurch visualizations


library(tidyverse)
library(here)
source(here("2_scripts","0_tools","topPercent.R"))
#-------------------------------------------------------------------------------
#LOAD DATA
nz_data <- read_csv(here("3_output", "airbnb_nz_preprocessed.csv"))
chch_data <- read_csv(here("3_output", "airbnb_chch_preprocessed.csv"))

#-------------------------------------------------------------------------------
#price plot
ggplot(nz_data, aes(x = price)) +
  geom_histogram(binwidth = 20) +
  coord_cartesian(xlim = c(0, 5000)) + # 0-5000 span
  labs(
    title = "Distribution of Airbnb Prices in New Zealand",
    x = "Price",
    y = "Count"
  )

ggplot(chch_data, aes(x = price)) +
  geom_histogram(binwidth = 10) +
  coord_cartesian(xlim = c(0, 2000)) + # 0-2000 span
  labs(
    title = "Distribution of Airbnb Prices in Christchurch City",
    x = "Price",
    y = "Count"
  )

#-------------------------------------------------------------------------------
#merge two plot into one
price_comparison <- bind_rows(
  nz_data |>
    mutate(area = "All New Zealand"),
  
  chch_data|>
    mutate(area = "Christchurch City")
)

price_plot <- ggplot(
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
    title = "Airbnb Price Distribution: New Zealand vs Christchurch City",
    x = "Price (NZD)",
    y = "Count",
    fill = "Area"
  )

#-------------------------------------------------------------------------------
# calculate days since last review

chch_data <- chch_data |>
  mutate(last_review = as.Date(last_review)) |>
  group_by(year_month) |>
  mutate(
    snapshot_date = max(last_review, na.rm = TRUE),
    days_since_last_review = as.numeric(snapshot_date - last_review)
  ) |>
  ungroup()


#-------------------------------------------------------------------------------
# calculate top 10% number of reviews
top_10_reviews <- topPercent(nz_data, nz_data$number_of_reviews, 0.1 )



top_10_reviews |>
  summarise(
    total_top_10 = n(),
    christchurch_count = sum(
      neighbourhood_group == "Christchurch City",
      na.rm = TRUE
    )
  )

ggsave(file.path(plots_dir, "airbnb_price_distribution.png"), price_plot,
       width = 9, height = 6, dpi = 150)
