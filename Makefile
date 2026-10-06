# ------------------------------------------------------------------------------
# Run the pipeline with make (from the project root). Only the steps whose
# inputs have changed are re-run, e.g. after adding a new month of Airbnb data
# or editing config.yaml.
# Runs every script in order instead.
# Do not use `make -j`, the steps must run one after another.
# ------------------------------------------------------------------------------

.PHONY: all check clean clean-all

OUT   := 03_output
DOC   := 04_documentation
PLOTS := 05_plots
DATA  := 01_data
SCR   := 02_scripts

RAW     := $(wildcard $(DATA)/01_airbnb_rawdata/listings_*.csv)
HELPERS := $(wildcard $(SCR)/00_tools/*.R)
TENANCY := $(DATA)/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv
CHCH    := $(DATA)/geographic_area_table_2026_chch.csv
WARDS   := $(DATA)/geographic-areas-table-2023.csv

# --- Check --------------------------------------------------------------------
# The step that writes several files is tracked by its first output.
FINAL := $(OUT)/airbnb_rental_properties_count_by_location.csv \
         $(OUT)/full_rental_summary_withpricediff.csv \
         $(OUT)/full_rental_summary_byward.csv \
         $(OUT)/airbnb_median_price_chch_central.csv \
         $(DOC)/chch_summary.md \
         $(PLOTS)/09_price_distribution_nz.png \
         $(PLOTS)/13_ward_price_airbnb_vs_rental.png

# Check runs first as it creates missing output folders and stops with a clear
# message if scripts, input files or config.yaml are wrong.
all: check $(FINAL)

check:
	Rscript pipeline.R --check

# --- Steps --------------------------------------------------------------------
# 01: merge raw Airbnb months, keep the configured area
$(OUT)/airbnb_chch_preprocessed.csv: $(SCR)/01_airbnb_preprocessing.R $(RAW) config.yaml $(HELPERS)
	Rscript $(SCR)/01_airbnb_preprocessing.R

# 02: tenancy data for the Airbnb date range
$(OUT)/tenancy_chch_preprocessed.csv: $(SCR)/02_tenancy_preprocessing.R $(RAW) $(TENANCY) $(CHCH) $(HELPERS)
	Rscript $(SCR)/02_tenancy_preprocessing.R

# 03, 04: cleaning
$(OUT)/airbnb_chch_cleaned.csv: $(SCR)/03_airbnb_cleaning.R $(OUT)/airbnb_chch_preprocessed.csv
	Rscript $(SCR)/03_airbnb_cleaning.R

$(OUT)/tenancy_chch_cleaned.csv: $(SCR)/04_tenancy_cleaning.R $(OUT)/tenancy_chch_preprocessed.csv
	Rscript $(SCR)/04_tenancy_cleaning.R

# 05: SA2 area code for each listing (Koordinates API; key only needed for new
# locations). area_code_lookup.csv is a cache.
$(OUT)/airbnb_chch_cleaned_witharea.csv: $(SCR)/05_airbnb_parallel_processing.R $(OUT)/airbnb_chch_cleaned.csv $(CHCH) config.yaml $(HELPERS)
	Rscript $(SCR)/05_airbnb_parallel_processing.R

# 06, 07: Summaries by SA2 and by ward
$(OUT)/full_rental_summary_bylocation.csv: $(SCR)/06_full_rental_summarise_location.R $(OUT)/airbnb_chch_cleaned_witharea.csv $(OUT)/tenancy_chch_cleaned.csv $(CHCH) config.yaml $(HELPERS)
	Rscript $(SCR)/06_full_rental_summarise_location.R

$(OUT)/full_rental_summary_byward.csv: $(SCR)/07_full_rental_summarise_ward.R $(OUT)/full_rental_summary_bylocation.csv $(WARDS) config.yaml $(HELPERS)
	Rscript $(SCR)/07_full_rental_summarise_ward.R

# 08: Airbnb data summary
$(DOC)/chch_summary.md: $(SCR)/08_airbnb_datasummary.R $(OUT)/airbnb_chch_preprocessed.csv $(HELPERS)
	Rscript $(SCR)/08_airbnb_datasummary.R

# 09: Airbnb plots
$(PLOTS)/09_price_distribution_nz.png: $(SCR)/09_airbnb_chch_visualisation.R $(OUT)/airbnb_chch_preprocessed.csv config.yaml $(HELPERS)
	Rscript $(SCR)/09_airbnb_chch_visualisation.R

# 10, 11, 12: Price and property comparisons
$(OUT)/airbnb_median_price_chch_central.csv: $(SCR)/10_airbnb_medianprice_chch_central.R $(OUT)/full_rental_summary_bylocation.csv config.yaml $(HELPERS)
	Rscript $(SCR)/10_airbnb_medianprice_chch_central.R

$(OUT)/full_rental_summary_withpricediff.csv: $(SCR)/11_full_rental_price_difference.R $(OUT)/full_rental_summary_bylocation.csv
	Rscript $(SCR)/11_full_rental_price_difference.R

$(OUT)/airbnb_rental_properties_count_by_location.csv: $(SCR)/12_full_rental_compare_properties.R $(OUT)/airbnb_chch_cleaned_witharea.csv $(OUT)/tenancy_chch_cleaned.csv config.yaml $(HELPERS)
	Rscript $(SCR)/12_full_rental_compare_properties.R

# 13: Rental vs Airbnb plots
$(PLOTS)/13_ward_price_airbnb_vs_rental.png: $(SCR)/13_full_rental_pricevisualisation.R $(OUT)/full_rental_summary_byward.csv $(HELPERS)
	Rscript $(SCR)/13_full_rental_pricevisualisation.R

clean:
	rm -f $(filter-out $(OUT)/area_code_lookup.csv,$(wildcard $(OUT)/*.csv)) \
	      $(PLOTS)/*.png \
	      $(DOC)/chch_cleaning_log.md $(DOC)/rental_bond_cleaning_log.md $(DOC)/chch_summary.md

clean-all: clean
	rm -f $(OUT)/area_code_lookup.csv
