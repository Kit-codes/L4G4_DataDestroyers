


#1. load library
library(tidyverse)
source('~/L4G4_DataDestroyers/my_tools/data_summary.R')

chch_data_all <- read.csv("resource/merged/airbnb_chch_merged_files.csv")

#2. caculate summary statistics for all columns(except last_review and licence) 
id_summary <- count_only_summary(chch_data_all, id)
name_summary <- count_only_summary(chch_data_all, name)
host_id_summary <- count_only_summary(chch_data_all, host_id)
host_name_summary <- count_only_summary(chch_data_all, host_name)
neighbourhood_group_summary <- categories_summary(chch_data_all, neighbourhood_group)
neighbourhood_summary <- categories_summary(chch_data_all, neighbourhood)
latitude_summary <- count_only_summary(chch_data_all, latitude)
longitude_summary <- count_only_summary(chch_data_all, longitude)
room_type_summary <- categories_summary(chch_data_all, room_type)
price_summary <- numeric_summary(chch_data_all, price)
minimum_nights_summary <- numeric_summary(chch_data_all, minimum_nights)
number_of_reviews_summary <- numeric_summary(chch_data_all, number_of_reviews)
reviews_per_month_summary <- numeric_summary(chch_data_all, reviews_per_month)
calculated_host_listings_count_summary <- numeric_summary(chch_data_all, calculated_host_listings_count)
availability_365_summary <- numeric_summary(chch_data_all, availability_365)
number_of_reviews_ltm_summary <- numeric_summary(chch_data_all, number_of_reviews_ltm)


# 3. output to a markdown file
summary_tables <- list(
  "ID" = id_summary,
  "Name" = name_summary,
  "Host ID" = host_id_summary,
  "Host Name" = host_name_summary,
  "Neighbourhood Group" = neighbourhood_group_summary,
  "Neighbourhood" = neighbourhood_summary,
  "Latitude" = latitude_summary,
  "Longitude" = longitude_summary,
  "Room Type" = room_type_summary,
  "Price" = price_summary,
  "Minimum Nights" = minimum_nights_summary,
  "Number of Reviews" = number_of_reviews_summary,
  "Reviews per Month" = reviews_per_month_summary,
  "Calculated Host Listings Count" = calculated_host_listings_count_summary,
  "Availability 365" = availability_365_summary,
  "Number of Reviews LTM" = number_of_reviews_ltm_summary
)

summary_md_file <- file.path(
  merged_folder,
  "chch_summary.md"
)

md_content <- c(
  "# Christchurch Airbnb Summary Statistics",
  ""
)

for (title in names(summary_tables)) {
  
  md_content <- c(
    md_content,
    paste0("## ", title),
    "",
    knitr::kable(
      summary_tables[[title]],
      format = "pipe"
    ),
    ""
  )
}

writeLines(
  md_content,
  summary_md_file
)

