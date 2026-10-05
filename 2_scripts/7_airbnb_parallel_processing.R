#-------------------------------------------------------------------------------
# Get the Stats NZ area code (SA2 2026) for each Airbnb listing using the
# Koordinates Query API.
#
# Only coordinates that are not already in the cached lookup
# (3_output/area_code_lookup.csv) are sent to the API, so adding new months of
# data only queries the new locations. If nothing is new, no API key is needed.

library(tidyverse)
library(httr2)
library(here)

#-------------------------------------------------------------------------------
# koordinates layer id and API key (key lives in .Renviron, never in the code)
layer_id <- "123515"
api_key  <- Sys.getenv("KOORDINATES_API_KEY")

#-------------------------------------------------------------------------------
input_file  <- here("3_output", "airbnb_chch_cleaned.csv")
output_file <- here("3_output", "airbnb_chch_cleaned_witharea.csv")
lookup_file <- here("3_output", "area_code_lookup.csv")
chch_file   <- here("1_data", "geographic_area_table_2026_chch.csv")

# load data ----------------------------------------------------------------

# ID read as text
listings <- read_csv(input_file,
                     col_types = cols(id = col_character(), host_id = col_character()))

# One key per location, so each location only needs to be queried once
listings <- listings |>
  mutate(coord_key = sprintf("%.7f,%.7f", latitude, longitude))


# functions ----------------------------------------------------------------

# builds the query for one location (x is longitude, y is latitude)
build_req <- function(lat, lon) {
  request("https://koordinates.com/services/query/v1/vector.json") |>
    req_url_query(key = api_key,
                  layer = layer_id,
                  x = sprintf("%.7f", lon),
                  y = sprintf("%.7f", lat),
                  max_results = 1,
                  with_field_names = "true")
}

# takes the answer from Koordinates and pulls out the area code
# gives NA if the query failed or the point isn't inside any area
get_area_info <- function(resp) {
  NA_location <- tibble(
    SA22026_code = NA_character_,
    SA22026_name = NA_character_
  )
  if (!inherits(resp, "httr2_response")) return(NA_location)
  if (resp_status(resp) != 200) return(NA_location)
  
  layers <- resp_body_json(resp)$vectorQuery$layers
  if (length(layers) == 0) return(NA_location)
  features <- layers[[1]]$features
  if (length(features) == 0) return(NA_location)
  
  props <- features[[1]]$properties
  
  # the area code column starts with SA2
  fields     <- names(props)
  code_field <- fields[grepl("^SA2", fields) & !grepl("NAME|ASCII", fields)][1]
  name_field <- fields[grepl("^SA2", fields) & grepl("NAME", fields)][1]
  
  tibble(
    SA22026_code = as.character(props[[code_field]]),
    SA22026_name = as.character(props[[name_field]])
  )
}


# look up only the NEW locations ---------------------------------------------

# existing cache (empty if this is the first run)
if (file.exists(lookup_file)) {
  lookup <- read_csv(lookup_file, col_types = cols(.default = col_character()))
} else {
  lookup <- tibble(coord_key = character(),
                   SA22026_code = character(),
                   SA22026_name = character())
}

new_locations <- listings |>
  filter(!is.na(latitude), !is.na(longitude), !coord_key %in% lookup$coord_key) |>
  distinct(coord_key, .keep_all = TRUE)

message(nrow(new_locations), " new locations to look up (",
        nrow(lookup), " already cached)")

if (nrow(new_locations) > 0) {
  
  if (!nzchar(api_key)) {
    stop("KOORDINATES_API_KEY is not set. Add it to .Renviron and restart R.")
  }
  
  reqs  <- map2(new_locations$latitude, new_locations$longitude, build_req)
  resps <- req_perform_parallel(reqs, on_error = "continue", max_active = 8)
  
  new_lookup <- tibble(
    coord_key = new_locations$coord_key,
    area_info = map(resps, get_area_info)
  ) |>
    unnest(area_info)
  
  if (all(is.na(new_lookup$SA22026_code))) {
    stop("No area codes came back. Check the api_key and layer_id.")
  }
  
  # only cache successful lookups, so failed requests are retried next run
  lookup <- bind_rows(lookup, filter(new_lookup, !is.na(SA22026_code))) |>
    distinct(coord_key, .keep_all = TRUE)
  
  write_csv(lookup, lookup_file)
}


# add the area codes to the listings -----------------------------------------

listings_with_area <- listings |>
  left_join(select(lookup, coord_key, SA22026_code), by = "coord_key") |>
  select(-coord_key)

# sanity check: the join must not add or lose rows
stopifnot(nrow(listings_with_area) == nrow(listings))

write_csv(listings_with_area, output_file)


# checks -----------------------------------------------------------------------

# listings with no area code
n_missing <- sum(is.na(listings_with_area$SA22026_code))
if (n_missing > 0) warning(n_missing, " listings have no SA2 area code")

# listings in an area from the Christchurch area table
chch <- read_csv(chch_file, col_types = cols(.default = col_character()))
cat("Listings with no area code:", n_missing, "\n")
cat("Listings outside the Christchurch area table:",
    sum(!listings_with_area$SA22026_code %in% chch$SA22026_code), "\n")