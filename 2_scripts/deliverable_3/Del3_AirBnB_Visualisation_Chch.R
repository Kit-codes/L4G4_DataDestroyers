
library(tidyverse)
source('~/L4G4_DataDestroyers/my_tools/topPercent.R')

nz_data <- read.csv("output/merged/airbnb_nz_merged_files.csv")
chch_data <- read.csv("output/merged/airbnb_chch_merged_files.csv")

# 5. price plot
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


# 6. merge two plot into one
price_comparison <- bind_rows(
  nz_data |>
    mutate(area = "All New Zealand"),
  
  chch_data|>
    mutate(area = "Christchurch City")
)

ggplot(
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


# 7. calculate the day since last review
publish_date <- as.Date("2026-06-19")

chch_data <- chch_data |>
  mutate(
    last_review = as.Date(last_review),
    days_since_last_review = as.numeric(
      publish_date - last_review
    )
  )

# 8. days since last review plot
ggplot(
  chch_data,
  aes(x = days_since_last_review)
) +
  coord_cartesian(xlim = c(-10, 1000)) + # 0-1000 span
  geom_histogram(
    binwidth = 5,
    na.rm = TRUE
  ) +
  labs(
    title = "Distribution of Days Since Last Review",
    x = "Days Since Last Review",
    y = "Count"
  )



# 9. calculate top 10% number of reviews
top_10_reviews <- topPercent(chch_data, chch_data$number_of_reviews, 0.1 )



top_10_reviews |>
  summarise(
    total_top_10 = n(),
    christchurch_count = sum(
      neighbourhood_group == "Christchurch City",
      na.rm = TRUE
    )
  )

