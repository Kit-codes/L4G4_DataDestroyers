#-------------------------------------------------------------------------------
# Group rental/airbnb summary by ward.

library(tidyverse)
library(here)


#-------------------------------------------------------------------------------
#load data
area_with_ward  <- read_csv(here("3_output", "full_rental_summary_byward.csv"))

str(area_with_ward)

area_with_ward$median_rent_night <- area_with_ward$median_rent/7
area_with_ward_diffs <- area_with_ward |> 
  mutate(price_diff = abs(median_airbnb_price-median_rent_night))

area_with_ward_long <- area_with_ward |> 
  pivot_longer(
    cols = c(median_airbnb_price,median_rent_night),     # 1. Which columns to pivot
    names_to = "Type",   # 2. Name of the column for old column headers
    values_to = "Price per night"    # 3. Name of the column for cell values
  )

price_plot <- ggplot(area_with_ward_long,
  aes(
    x = `Price per night`,
    fill = Type
  )
) +
  geom_histogram(
    binwidth = 5,
    position = "identity",
    alpha = 0.5
  ) +
  coord_cartesian(
    xlim = c(0, 300)
  ) +
  labs(
    title = "Nightly Price Distribution: Rental vs Airbnb",
    x = "Price (NZD)",
    y = "Count",
    fill = "Area"
  )
price_plot


price_plot2 <- ggplot(area_with_ward_diffs,aes(x = WARD2023_name,y = price_diff))+
      geom_bar(stat = "identity")

price_plot2
