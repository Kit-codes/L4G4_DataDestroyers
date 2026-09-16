# 1. load library

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

# 5. filter Christchurch city listings
chch_data_all <- nz_data_all |>
  filter(neighbourhood_group == "Christchurch City")

# 6. save all New Zealand listings and Christchurch listings to csv file.
write_csv(nz_data_all, nz_merged_file)
write_csv(chch_data_all, chch_merged_file)

