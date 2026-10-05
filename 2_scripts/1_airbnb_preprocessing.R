# ------------------------------------------------------------------------------
# AirBnB Data Pre Processing
# Reads every listings_YYYY_MM.csv in the raw folder
#
library(tidyverse)
library(here)
#-------------------------------------------------------------------------------
#LOAD DATA

listings_folder <- here("1_data","1_airbnb_rawdata")

listings_files <- list.files(
  path = listings_folder,
  pattern = "^listings_\\d{4}_\\d{2}\\.csv$",
  full.names = TRUE
)
#-------------------------------------------------------------------------------
#Check for contents in folder
if (length(listings_files) == 0) stop("No listings_YYYY_MM.csv files in ", listings_folder)

other_csv <- setdiff(list.files(listings_folder, pattern = "\\.csv$", full.names = TRUE), listings_files)

if (length(other_csv) > 0) {
  warning("Ignore files that don't match listings_YYYY_MM.csv: ",
          paste(basename(other_csv), collapse = ", "))
}

#Stop if two files have duplicate content
hashes <- unname(tools::md5sum(listings_files))
dups <- listings_files[duplicated(hashes) | duplicated(hashes, fromLast = TRUE)]
if (length(dups) > 0) {
  stop("Identical raw files (same content, different names): ",
       paste(basename(dups), collapse = ", "))
}
#-------------------------------------------------------------------------------
#Create merged file
nz_data_all <- map_dfr(
  listings_files,
  ~ read_csv(.x) |>
    mutate(
      year_month = str_extract(basename(.x), "\\d{4}_\\d{2}")
    )
)
#-------------------------------------------------------------------------------
# Filter Christchurch city listings
chch_data_all <- nz_data_all |>
  filter(neighbourhood_group == "Christchurch City")
#-------------------------------------------------------------------------------
#OUTPUT
write_csv(nz_data_all, here("3_output", "airbnb_nz_preprocessed.csv"))
write_csv(chch_data_all, here("3_output","airbnb_chch_preprocessed.csv"))
