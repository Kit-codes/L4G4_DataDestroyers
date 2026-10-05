# ------------------------------------------------------------------------------
# Settings shared by the pipeline scripts
#
library(here)
# ------------------------------------------------------------------------------
# Rental bond window, keep quarters that start on or after tenancy_start and on
# or before tenancy_end. Extend tenancy_end when new quarters are published.
tenancy_start <- as.Date("2025-10-01")
tenancy_end   <- as.Date("2026-08-31")