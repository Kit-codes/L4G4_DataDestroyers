#--- Parallel Processing -------------------------------------------------------
# Get the Stats NZ area code (SA2 2026) for each Airbnb listing using the 
# Koordinates Query API.
#
# Locations already in 03_output/area_code_lookup.csv are NOT queried again, so
# when new months are added only their new locations hit the API. The API key
# is only needed if there is something new to look up.
# Key: KOORDINATES_API_KEY in the project's .Renviron (see .Renviron.example).
#
#load library
library(tidyverse)
library(httr2)
library(here)
source(here("02_scripts", "00_tools", "config.R"))   # must provide get_api_key()

#--- Koordinates Layer Id ------------------------------------------------------
# Statistical Area 2 2026 (set in config.yaml)
layer_id <- get_config()$koordinates_layer_id

#--- Load Data -----------------------------------------------------------------
input_file  <- here("03_output","airbnb_chch_cleaned.csv")
output_file <- here("03_output","airbnb_chch_cleaned_witharea.csv")
lookup_file <- here("03_output","area_code_lookup.csv")
chch_file   <- here("01_data","geographic_area_table_2026_chch.csv")

# ID read as text
listings <- read_csv(input_file,
                     col_types = cols(id = col_character(), 
                                      host_id = col_character()))

# One key per location, so each location only needs to be queried once
listings <- listings |>
  mutate(coord_key = sprintf("%.7f,%.7f", latitude, longitude))

#--- Functions -----------------------------------------------------------------
# Builds the query for one location (x is longitude, y is latitude)
build_req <- function(lat, lon, api_key) {
  request("https://koordinates.com/services/query/v1/vector.json") |>
    req_url_query(key = api_key,
                  layer = layer_id,
                  x = sprintf("%.7f", lon),
                  y = sprintf("%.7f", lat),
                  max_results = 1,
                  with_field_names = "true")
}

# Takes the answer from Koordinates and pulls out the area code. Gives NA if the 
# query failed or the point isn't inside any area
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
  
  # The area code column must start with SA2
  fields     <- names(props)
  code_field <- fields[grepl("^SA2", fields) & !grepl("NAME|ASCII", fields)][1]
  name_field <- fields[grepl("^SA2", fields) & grepl("NAME", fields)][1]
  
  tibble(
    SA22026_code = as.character(props[[code_field]]),
    SA22026_name = as.character(props[[name_field]])
  )
}

#--- Work Out Which Locations Need Querying ------------------------------------
unique_locations <- listings |>
  filter(!is.na(latitude), !is.na(longitude)) |>
  distinct(coord_key, .keep_all = TRUE)

# Existing lookup (if any)
lookup <- if (file.exists(lookup_file)) {
  read_csv(lookup_file, col_types = cols(.default = col_character()))
} else {
  tibble(coord_key = character(),
         SA22026_code = character(),
         SA22026_name = character())
}

# Only locations not already in the lookup
new_locations <- unique_locations |>
  filter(!coord_key %in% lookup$coord_key)

message(nrow(unique_locations), " unique locations: ",
        nrow(unique_locations) - nrow(new_locations), " already in the lookup, ",
        nrow(new_locations), " to query")

#--- Query New Locations -------------------------------------------------------
if (nrow(new_locations) > 0) {
  
  # Stops with setup instructions if the key isn't set
  api_key <- get_api_key()
  
  # Test one query works before sending the rest
  test_resp <- build_req(new_locations$latitude[1], 
                         new_locations$longitude[1], 
                         api_key) |>
    req_perform()
  
  message("Test query status: ", resp_status(test_resp))
  print(get_area_info(test_resp))   # should be a 6 digit area code
  
  reqs  <- map2(new_locations$latitude, new_locations$longitude,
                build_req, api_key = api_key)
  resps <- req_perform_parallel(reqs, on_error = "continue", max_active = 8)
  
  new_lookup <- tibble(
    coord_key = new_locations$coord_key,
    area_info = map(resps, get_area_info)
  ) |>
    unnest(area_info)
  
  if (all(is.na(new_lookup$SA22026_code))) {
    stop("No area codes came back. Check KOORDINATES_API_KEY and layer_id.")
  }
  
  # Only keep answers we got, so failed ones are retried on the next run
  lookup <- bind_rows(lookup, filter(new_lookup, !is.na(SA22026_code)))
  write_csv(lookup, lookup_file)
  
  message(sum(is.na(new_lookup$SA22026_code)),
          " new location(s) returned no area code and will be retried next run")
}

#--- Add Area Code to Listings -------------------------------------------------
listings_with_area <- listings |>
  left_join(select(lookup, coord_key, SA22026_code), by = "coord_key") |>
  select(-coord_key)

#--- Output --------------------------------------------------------------------
write_csv(listings_with_area, output_file)

#--- Sanity Test ---------------------------------------------------------------
# Listings with no area code
message("Listings with no area code: ", sum(is.na(listings_with_area$SA22026_code)))

# Listings in an area from the Christchurch area table
chch <- read_csv(chch_file, col_types = cols(.default = col_character()))
message("Listings in a Christchurch area: ",
        sum(listings_with_area$SA22026_code %in% chch$SA22026_code))