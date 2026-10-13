#--- Pipeline ------------------------------------------------------------------
# Runs the whole project with one call: checks the folders and config.yaml,
# then runs every numbered script in 02_scripts/ in order.
#
# From the terminal (run from the project root):
#   Rscript pipeline.R              # check, then run every script
#   Rscript pipeline.R --check      # only check folders and config.yaml
#   Rscript pipeline.R --from 5     # resume from script 05 onwards
#
# With make, only the steps whose inputs have changed are re-run
# (see the Makefile; do not use `make -j`):
#   make
#
# From R / RStudio console:
#   source("pipeline.R")
#   run_pipeline()                  # run every script
#   run_pipeline(from = 5)          # resume from script 05 onwards
#   check_project_structure()       # only check folders, scripts and inputs
#
# Adding new Airbnb months:
#   Drop the new listings_YYYY_MM.csv.gz files into 01_data/01_airbnb_rawdata/
#   and run the pipeline again. The month range, tenancy date window,
#   latest-snapshot filters and API lookups all follow from that folder.
#
# Settings:
#   Analysis settings live in config.yaml.
#   KOORDINATES_API_KEY must be set in .Renviron (copy .Renviron.example) when
#   there are listing locations not already in 03_output/area_code_lookup.csv.
#   03_output/ is not stored in git, so the first run on a fresh clone create it.
#
#--- Expected project layout ---------------------------------------------------
#   01_data/            raw and reference data (inputs, never edited by scripts)
#   02_scripts/         numbered scripts, plus 00_tools/ helper functions
#   03_output/          generated tables plots go in 03_output/00_plots/
#   04_documentation/   cleaning logs, data summary and report
#   config.yaml         analysis settings
# Missing output folders are created below; missing code or input files are
# reported together as one error.
#
#--- Pipeline ------------------------------------------------------------------

#Read API key file
readRenviron(".Renviron")


# Folders that can be created if missing as they hold generated files
create_dirs <- c(
  "01_data",
  file.path("01_data", "01_airbnb_rawdata"),
  "03_output",
  "04_documentation",
  file.path("03_output", "00_plots")
)

# Folders that hold code. A missing one is an error.
code_dirs <- c("02_scripts", file.path("02_scripts", "00_tools"))

# Input files the scripts read but cannot be generated.
required_inputs <- c(
  "config.yaml",
  file.path("01_data", "Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv.gz"),
  file.path("01_data", "geographic_area_table_2026_chch.csv"),
  file.path("01_data", "geographic-areas-table-2023.csv.gz")
)

required_tools <- file.path("02_scripts", "00_tools",
                            c("config.R", "data_summary.R", "topPercent.R"))

script_pattern <- "^[0-9]+_.*\\.R$"

# Find the project root
find_project_root <- function() {
  file_arg <- grep("^--file=", commandArgs(FALSE), value = TRUE)
  if (length(file_arg) > 0) {
    return(normalizePath(dirname(sub("^--file=", "", file_arg[1]))))
  }
  normalizePath(getwd())
}

#--- Structure check -----------------------------------------------------------
# Check the folders, scripts and input files. Missing output folders are created
# anything that can't be created (code, input data) is collected and reported 
# together  in one error.
check_project_structure <- function(root = find_project_root(), create = TRUE) {
  problems <- character()
  created  <- character()
  p <- function(...) file.path(root, ...)
  
# Folders
  for (d in create_dirs) {
    if (!dir.exists(p(d))) {
      if (create) {
        dir.create(p(d), recursive = TRUE)
        created <- c(created, d)
      } else {
        problems <- c(problems, paste0("Missing folder: ", d))
      }
    }
  }
  
# Code, folders and scripts
  for (d in code_dirs) {
    if (!dir.exists(p(d))) problems <- c(problems, paste0("Missing folder: ", d))
  }
  scripts <- character()
  if (dir.exists(p("02_scripts"))) {
    scripts <- list.files(p("02_scripts"), pattern = script_pattern)
    if (length(scripts) == 0) {
      problems <- c(problems, "No numbered scripts (e.g. 01_name.R) found in 02_scripts")
    }
    nums <- sub("^([0-9]+)_.*", "\\1", scripts)
    dup  <- unique(as.integer(nums)[duplicated(as.integer(nums))])
    for (n in dup) {
      problems <- c(problems, paste0(
        "More than one script is numbered ", n, ": ",
        paste(scripts[as.integer(nums) == n], collapse = ", ")))
    }
    empty <- scripts[file.size(p("02_scripts", scripts)) == 0]
    if (length(empty) > 0) {
      message("Note: empty scripts will be skipped: ", paste(empty, collapse = ", "))
    }
  }
  for (f in required_tools) {
    if (dir.exists(p("02_scripts", "00_tools")) && !file.exists(p(f))) {
      problems <- c(problems, paste0("Missing helper script: ", f))
    }
  }
  
# Input data
  for (f in required_inputs) {
    if (!file.exists(p(f))) {
      hint <- ""
      alt  <- sub("^01_data", "1_data", f)
      if (file.exists(p(alt))) hint <- paste0(" (found at ", alt, " - move it)")
      problems <- c(problems, paste0("Missing input file: ", f, hint))
    }
  }
  raw_dir <- p("01_data", "01_airbnb_rawdata")
  listings <- list.files(raw_dir, pattern = "^listings_\\d{4}_\\d{2}\\.csv.gz$")
  if (length(listings) == 0) {
    hint <- ""
    if (dir.exists(p("01_data", "1_airbnb_rawdata"))) {
      hint <- " (found 01_data/1_airbnb_rawdata - rename it to 01_airbnb_rawdata)"
    }
    problems <- c(problems, paste0(
      "No listings_YYYY_MM.csv.gz files in 01_data/01_airbnb_rawdata", hint))
  }
  
  if (length(created) > 0) {
    message("Created missing folders: ", paste(created, collapse = ", "))
  }
  if (length(problems) > 0) {
    stop("Project structure check failed:\n",
         paste0("  - ", problems, collapse = "\n"))
  }
  message("Project structure OK (", length(listings), " Airbnb months, ",
          length(scripts), " scripts).")
  invisible(TRUE)
}

#--- Run Pipeline --------------------------------------------------------------
run_pipeline <- function(from = 1L, check_only = FALSE) {
  root <- find_project_root()
  setwd(root)
  check_project_structure(root)
  
# Check config.yaml before any script runs
  library(here)
  helpers <- new.env()
  source(here("02_scripts", "00_tools", "config.R"), local = helpers)
  invisible(helpers$get_config())
  message("config.yaml OK")
  if (check_only) return(invisible(TRUE))
  
  scripts <- list.files(here("02_scripts"), pattern = script_pattern, full.names = TRUE)
  nums    <- as.integer(sub("^([0-9]+)_.*", "\\1", basename(scripts)))
  scripts <- scripts[order(nums)]
  nums    <- sort(nums)
  keep    <- file.size(scripts) > 0 & nums >= from
  scripts <- scripts[keep]
  if (length(scripts) == 0) stop("No scripts to run (from = ", from, ").")
  
# Plots are written to 03_output/00_plots/ by save_plot().
  grDevices::pdf(NULL)
  on.exit(grDevices::dev.off(), add = TRUE)
  
  start <- Sys.time()
  for (script in scripts) {
    cat("\n=====", basename(script), "=====\n")
    t0 <- Sys.time()
    tryCatch(
      source(script, local = new.env(), print.eval = TRUE),
      error = function(e) {
        stop("Pipeline stopped at ", basename(script), ":\n  ", conditionMessage(e),
             "\nFix the problem, then resume with: Rscript pipeline.R --from ",
             as.integer(sub("^([0-9]+)_.*", "\\1", basename(script))))
      }
    )
    cat(sprintf("(%s done in %.1fs)\n", basename(script),
                as.numeric(difftime(Sys.time(), t0, units = "secs"))))
  }
  
  plots <- list.files(here("03_output", "00_plots"), pattern = "\\.png$")
  cat(sprintf("\nDone in %.1f min. %d plot(s) in 03_output/00_plots/, tables in 03_output/.\n",
              as.numeric(difftime(Sys.time(), start, units = "mins")), length(plots)))
  invisible(TRUE)
}

#--- Command line entry point --------------------------------------------------

if (!interactive() && sys.nframe() == 0L) {
  args <- commandArgs(trailingOnly = TRUE)
  from <- 1L
  if ("--from" %in% args) {
    from <- suppressWarnings(as.integer(args[which(args == "--from") + 1]))
    if (is.na(from)) stop("--from needs a script number, e.g. --from 5")
  }
  run_pipeline(from = from, check_only = "--check" %in% args)
}