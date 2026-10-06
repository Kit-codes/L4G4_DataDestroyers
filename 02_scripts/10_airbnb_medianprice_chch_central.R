#--- Join ----------------------------------------------------------------------
# Median price for Chistchurch central Airbnb properties
# Load Libraries
library(tidyverse)
library(dplyr)
library(here)
source(here("02_scripts", "00_tools", "config.R"))
cfg <- get_config()

#--- Load Data -----------------------------------------------------------------
full_summary <- read.csv(here("03_output","full_rental_summary_bylocation.csv"))

#--- Median Price of Christchurch central Airbnbs ------------------------------
median_chch_central <- full_summary[full_summary$SA22026_name == cfg$central_sa2_name,"median_Airbnb_price"]
if (length(median_chch_central) == 0) {
  stop("No SA2 named '", cfg$central_sa2_name, "' in the summary. Check `central_sa2_name` in config.yaml.",
       call. = FALSE)
}
median_chch_central[1]

#--- Output --------------------------------------------------------------------
write_csv(
  tibble(SA22026_name = cfg$central_sa2_name,
         median_Airbnb_price = median_chch_central[1]),
  here("03_output", "airbnb_median_price_chch_central.csv")
)




