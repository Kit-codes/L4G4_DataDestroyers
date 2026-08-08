# 1. install tidyverse packages, uncommetonly need run it once.
# install.packages("tidyverse")

# 2. load library
library(tidyverse)

# 3. setting folder and file path
listings_folder <- "resource"
merged_folder <- file.path("resource", "merged")
dir.create(merged_folder, recursive = TRUE, showWarnings = FALSE)
nz_merged_file <- file.path(merged_folder, "nz_merged_files.csv")
chch_merged_file <- file.path(merged_folder, "chch_merged_files.csv")

listings_files = list.files(
  path = listings_folder,
  pattern = "\\.csv$",
  full.names = TRUE
)

# 4. read all new zealand listings files and add year_month column
nz_data_all <- map_dfr(
  listings_files,
  ~ read_csv(.x) |>
    mutate(
      year_month = str_extract(basename(.x), "\\d{4}_\\d{2}")
    )
)

# 5. filter christchurch city listings
chch_data_all <- nz_data_all |>
  filter(neighbourhood_group == "Christchurch City")

# 6. save all new zealand listings and christchruch listings to csv file.
write_csv(nz_data_all, nz_merged_file)
write_csv(chch_data_all, chch_merged_file)



# 7. define some function for categories and numeric column
# only find count
count_only_summary <- function(dataset, column) {
  dataset |>
    group_by(year_month) |>
    summarise(
      count = sum(!is.na({{ column }})),
      unique_count = n_distinct({{ column }}, na.rm = TRUE),
      missing = sum(is.na({{ column }})),
      .groups = "drop"
    )
}

# count by categories
categories_summary <- function(dataset, column) {
  dataset |>
    group_by(year_month) |>
    count(
      {{column}}
    )
}

# min, max, mean, std
numeric_summary <- function(dataset, column) {
  dataset |>
    group_by(year_month) |>
    summarise(
      min = if (all(is.na({{ column }}))) NA_real_
      else min({{ column }}, na.rm = TRUE),
      max = if (all(is.na({{ column }}))) NA_real_
      else max({{ column }}, na.rm = TRUE),
      mean = if (all(is.na({{ column }}))) NA_real_
      else mean({{ column }}, na.rm = TRUE),
      std = if (all(is.na({{ column }}))) NA_real_
      else sd({{ column }}, na.rm = TRUE),
      missing = sum(is.na({{ column }})),
      .groups = "drop"
    )
}

# 8. caculate summary statistics for all columns(except last_review and licence) 
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

# 9. output to a markdown file
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
