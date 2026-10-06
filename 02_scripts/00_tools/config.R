# --- Configurations For Pipeline ----------------------------------------------
# Shared helpers for the pipeline scripts.
# To be sourced at the top of all scripts
# use (source(here("02_scripts", "00_tools", "config.R")))
#
# Load libraries
library(tidyverse)
library(here)
#
#--- Airbnb months -------------------------------------------------------------
# One row per raw listings file with its year_month ("2026_06") and file path.
# New months are picked up automatically by using drop listings_YYYY_MM.csv into
# 01_data/01_airbnb_rawdata and re running the pipeline.

get_airbnb_months <- function() {
  files <- list.files(
    here("01_data", "01_airbnb_rawdata"),
    pattern = "^listings_\\d{4}_\\d{2}\\.csv$",
    full.names = TRUE
  )
  if (length(files) == 0) {
    stop("No listings_YYYY_MM.csv files found in 01_data/01_airbnb_rawdata",
         call. = FALSE)
  }
  tibble(
    file       = files,
    year_month = str_extract(basename(files), "\\d{4}_\\d{2}")
  ) |>
    arrange(year_month)
}

latest_airbnb_month   <- function() max(get_airbnb_months()$year_month)
earliest_airbnb_month <- function() min(get_airbnb_months()$year_month)

# --- Time Frame of Script -----------------------------------------------------
# first / last day of that month, as Dates
month_start <- function(year_month) as.Date(paste0(gsub("_", "-", year_month),
                                                   "-01"))
month_end   <- function(year_month) {
  seq(month_start(year_month), by = "month", length.out = 2)[2] - 1
}

# Date the latest Airbnb snapshot was collected.
# To use the real date, set AIRBNB_COLLECTION_DATE=YYYY-MM-DD in .Renviron.
get_collection_date <- function() {
  cfg_date <- get_config()$collection_date
  if (!is.null(cfg_date)) return(as.Date(as.character(cfg_date)))
  month_end(latest_airbnb_month())
}

# --- API key ------------------------------------------------------------------
# Koordinates API key, read from KOORDINATES_API_KEY in the projects .Renviron
get_api_key <- function() {
  key <- Sys.getenv("KOORDINATES_API_KEY", unset = "")
  if (!nzchar(key)) {
    stop(
      "KOORDINATES_API_KEY is not set.\n",
      "  1. Copy .Renviron.example to .Renviron in the project root\n",
      "  2. Put your Koordinates key after KOORDINATES_API_KEY=\n",
      "  3. Re-run (R reads .Renviron at startup, so restart R if interactive)",
      call. = FALSE
    )
  }
  key
}
# ---- Config and checks -------------------------------------------------------
# Read config.yaml and check it before anything runs
get_config <- function() {
  path <- here("config.yaml")
  if (!file.exists(path)) stop("config.yaml not found in the project root", call. = FALSE)
  cfg <- yaml::read_yaml(path)
  
  text_settings <- c("area", "koordinates_layer_id", "dwelling_type",
                     "number_of_beds", "central_sa2_name")
  missing <- setdiff(text_settings, names(cfg))
  if (length(missing) > 0) {
    stop("config.yaml is missing: ", paste(missing, collapse = ", "), call. = FALSE)
  }
  for (name in text_settings) {
    value <- cfg[[name]]
    if (is.null(value) || length(value) != 1 || is.na(value) || !nzchar(as.character(value))) {
      stop("config.yaml: '", name, "' must be a single non-empty value", call. = FALSE)
    }
    cfg[[name]] <- as.character(value)
  }
  if (!is.null(cfg$collection_date)) {
    d <- as.character(cfg$collection_date)
    if (length(d) != 1 || !grepl("^\\d{4}-\\d{2}-\\d{2}$", d) ||
        is.na(as.Date(d, format = "%Y-%m-%d"))) {
      stop("config.yaml: 'collection_date' must be a real date as YYYY-MM-DD, or null",
           call. = FALSE)
    }
  }
  cfg
}

# Stop with a clear message if a data frame lacks columns we rely on.
check_columns <- function(data, cols, name) {
  missing <- setdiff(cols, names(data))
  if (length(missing) > 0) {
    stop(name, " is missing expected column(s): ", paste(missing, collapse = ", "),
         call. = FALSE)
  }
  invisible(data)
}

# Warning if there is a gap in the run of Airbnb months (e.g. 2026_05 and 2026_07
# present but 2026_06 missing).
check_month_gaps <- function(months = get_airbnb_months()$year_month) {
  expected <- format(seq(month_start(min(months)), month_start(max(months)),
                         by = "month"), "%Y_%m")
  gaps <- setdiff(expected, months)
  if (length(gaps) > 0) {
    warning("Missing Airbnb month(s): ", paste(gaps, collapse = ", "), call. = FALSE)
  }
  invisible(months)
}

#--- API key -------------------------------------------------------------------
# Koordinates API key, read from KOORDINATES_API_KEY in the project's .Renviron
get_api_key <- function() {
  key <- Sys.getenv("KOORDINATES_API_KEY", unset = "")
  if (!nzchar(key)) {
    stop(
      "KOORDINATES_API_KEY is not set.\n",
      "  1. Create .Renviron in the project root\n",
      "  2. Put your Koordinates key after KOORDINATES_API_KEY=\n",
      "  3. Re-run.",
      call. = FALSE
    )
  }
  key
}

#--- Plots ---------------------------------------------------------------------
# Save a ggplot to 03_output/00_plots/<name>.png. Use a name that starts with the script
# number, e.g. save_plot(p, "09_price_distribution_nz").
save_plot <- function(plot, name, width = 9, height = 6, dpi = 150) {
  dir.create(here("03_output", "00_plots"), showWarnings = FALSE, recursive = TRUE)
  path <- here("03_output", "00_plots", paste0(name, ".png"))
  ggsave(path, plot = plot, width = width, height = height, dpi = dpi, bg = "white")
  message("  plot saved: 03_output/00_plots/", basename(path))
  invisible(path)
}