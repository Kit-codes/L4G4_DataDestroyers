# Deliverable 5: get the Stats NZ area code (SA2 2026) for each Airbnb listing
# using the Koordinates Query API.


# 1. load library --------------------------------------------------------

library(tidyverse)
library(httr2)

# 2. setup ---------------------------------------------------------------

layer_id <- "123515"
api_key  <- "" # paste api key here

input_file  <- "output/cleaned/chch_listings_clean.csv.gz"
output_file <- "output/cleaned/chch_listings_with_area.csv.gz"
lookup_file <- "output/cleaned/area_code_lookup.csv"
chch_file   <- "resource/geographic_area_table_2026_chch.csv"


# 3. load data -----------------------------------------------------------

# ID read as text
listings <- read_csv(input_file,
                     col_types = cols(id = col_character(), host_id = col_character()))

# One key per location, so each location only needs to be queried once
listings <- listings |>
  mutate(coord_key = sprintf("%.7f,%.7f", latitude, longitude))


# 4. functions -----------------------------------------------------------

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
  if (!inherits(resp, "httr2_response")) return( NA_location )
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


# 5. test one query ------------------------------------------------------

test_resp <- build_req(listings$latitude[1], listings$longitude[1]) |>
  req_perform()

resp_status(test_resp)
get_area_info(test_resp) # should be a 6 digit area code


# 6. query all locations ------------------------------------------------

# if the lookup file already exists use it instead of querying again
if (file.exists(lookup_file)) {
  
  lookup <- read_csv(lookup_file, col_types = cols(.default = col_character()))
  
} else {
  
  unique_locations <- listings |>
    filter(!is.na(latitude), !is.na(longitude)) |>
    distinct(coord_key, .keep_all = TRUE)
  
  reqs  <- map2(unique_locations$latitude, unique_locations$longitude, build_req)
  resps <- req_perform_parallel(reqs, on_error = "continue", max_active = 8)
  
  lookup <- tibble(
    coord_key = unique_locations$coord_key,
    area_info = map(resps, get_area_info)
  ) |>
    unnest(area_info)
  
  if (all(is.na(lookup$SA22026_code))) {
    stop("No area codes came back. Check the api_key and layer_id.")
  }
  
  write_csv(lookup, lookup_file)
}


# 7. add the area codes to the listings ----------------------------------

listings_with_area <- listings |>
  left_join(select(lookup, coord_key, SA22026_code), by = "coord_key") |>
  select(-coord_key)

write_csv(listings_with_area, output_file)


# 8. checks! -------------------------------------------------------------

# listings with no area code
sum(is.na(listings_with_area$SA22026_code))

# listings in an area from the Christchurch area table
chch <- read_csv(chch_file, col_types = cols(.default = col_character()))
mean(listings_with_area$SA22026_code %in% chch$SA22026_code)

