# Christchurch Rental Pipeline Design Principles

L4G4 DataDestroyers | DATA201/422 group project

Our R pipeline prepares Christchurch Airbnb listings and rental bond data, adds SA2 2026 area codes, and produces descriptive comparisons of prices and rental counts. National data supports the initial exploration, while the final comparisons focus on Christchurch. Sections 1 to 4 describe the original uploaded scripts. Section 5 lists the issues identified during review. No changes to the original code have been made for this version of the document.

## 1 Inputs to the pipeline

Airbnb inputs are the New Zealand listings CSV snapshots in 1_data/1_airbnb_rawdata, sourced from Inside Airbnb. Each row is a listing observed in a snapshot. The pipeline reads listing and host IDs, location coordinates, neighbourhood fields, room type, price, review information and availability. It extracts year_month from filenames containing YYYY_MM. A listing can therefore appear in several snapshots; id alone is not a unique key across the combined data.

The rental input is 1_data/Detailed-Quarterly-Tenancy-Q1-2020-Q3-2026.csv, sourced from Tenancy Services. It contains quarter dates, Location Id, dwelling type, bedroom category, bond counts and weekly rental statistics. The pipeline selects dates from 1 October 2025 to 30 June 2026 and restricts locations using 1_data/geographic_area_table_2026_chch.csv.

The geographic table supplies Christchurch SA22026_code and SA22026_name values. Airbnb coordinates are queried against the Stats NZ SA2 2026 layer through the Koordinates Query API, using layer_id 123515. The original script defines an api_key parameter. It performs a live test request before checking whether a saved 3_output/area_code_lookup.csv can be reused for the bulk lookup.

## 2 Outputs from the pipeline

Intermediate CSVs in 3_output include airbnb_nz_preprocessed.csv, airbnb_chch_preprocessed.csv, tenancy_nz_preprocessed.csv and tenancy_chch_preprocessed.csv. Cleaning produces airbnb_chch_cleaned.csv and tenancy_chch_cleaned.csv. Script 7 specifies area_code_lookup.csv and airbnb_chch_cleaned_witharea.csv. as its outputs; the trailing period is part of the latter filename in the original code. These are file definitions in the scripts, not confirmation that the complete pipeline ran successfully.

The comparison outputs are full_rental_summary_bylocation.csv, full_rental_summary_withpricediff.csv and airbnb_rental_properties_count_by_location.csv. They contain pooled area price summaries, absolute nightly price differences, and the selected snapshot comparison of distinct Airbnb listings with active rental bonds, respectively.

Documentation outputs are chch_summary.md, chch_cleaning_log.md and rental_bond_cleaning_log.md in 4_documentation. Exploratory plots, the Christchurch Central median and the largest price difference are displayed during interactive execution; the scripts do not save separate figure or result files for these displays.

## 3 Main steps in the pipeline

### Preprocess and inspect the data

Scripts 1 and 2 combine Airbnb snapshots, select Christchurch listings, and filter rental data by date and Christchurch SA2 codes. Script 3 uses reusable summary functions to describe Airbnb fields by year_month, including counts, missingness and numerical summaries. Script 4 displays price histograms for New Zealand and Christchurch, calculates days since the last review relative to 19 June 2026, and selects the top 10 percent of combined New Zealand listing observations by review count, without retaining ties beyond the selected proportion.

### Clean the datasets

Script 5 removes license, neighbourhood_group, name and host_name where present, then drops rows with missing price. It records the input and output row counts and the number removed. Missing prices are not imputed. Script 6 applies select(-any_of(dropped_cols)) with four dotted column names. Its stated intention is to remove unused rental statistics while retaining Median Rent and bond counts. Both scripts write cleaned data and cleaning logs. Other missing fields are retained; the cleaning does not claim to remove every missing value.

### Add SA2 area codes

Script 7 builds a coordinate key using latitude and longitude rounded to seven decimal places. After a single test request, it queries distinct available coordinates rather than every listing row, using at most eight concurrent requests, and caches the results. Failed bulk queries or unmatched points receive missing SA2 values. A left join attaches area codes to listing rows, and checks report missing codes and membership in the Christchurch area table.

### Summarise and compare prices

Script 8 groups all cleaned Airbnb observations by SA2 and calculates median_Airbnb_price using median(price) and Number_of_Airbnb_properties using table(SA22026_code)[1]. It sums the reported counts into a check object. Rental rows are restricted to Dwelling Type = ALL and Number Of Beds = ALL before grouping by location. Median_rent is calculated as median(`Median Rent`); Number_of_rental_bonds is calculated as max(`Total Bonds`) across the selected quarters. Neither calculation specifies na.rm = TRUE. A full join retains areas appearing in either summary. Script 9 subsets the summary using the exact area name Christchurch Central and evaluates the first selected median value. Script 10 divides weekly rental median by seven, calculates the absolute difference from the Airbnb median, and displays the area or areas with the largest difference.

### Compare listing and bond counts

Script 11 counts distinct Airbnb id values by SA2 for year_month = 2026_06. It filters rental rows using TimeFrame == "2026/04/01", together with ALL dwelling and bedroom categories, and takes Active Bonds as the rental count. A full join preserves unmatched areas and adds area names. The script replaces missing values in both count columns with zero, calculates count_difference = airbnb_count - rental_count, and adds names from distinct SA2 code and name pairs in the API lookup. It prints area counts and total counts before saving the CSV.

These are descriptive comparisons. The pooled price analysis counts listing observations across snapshots and uses all retained room types. Its rental median is a median of quarterly medians, not a median calculated from individual tenancies. The count comparison uses cleaned listings, so listings without prices are excluded. Active Bonds is a bond measure rather than a verified count of all rental homes. No bedroom or bed totals, occupancy estimates, or causal effects are calculated.

## 4 Coding and software strategies

### Separate data code and outputs

The project uses 1_data for source files, 2_scripts for processing code, 3_output for generated CSVs, and 4_documentation for written descriptions and logs. Scripts read raw inputs and write new files rather than editing source data. This follows the Monday lecture principles of separating project components and preserving original data for audit. Existing z_Bin material is archived work and is not part of the active pipeline.

### Use project paths and small scripts

Files are located with here() relative to the project root. The RStudio project provides the entry point, and scripts do not change the working directory with setwd(). Numbered scripts divide the work into preprocessing, inspection, cleaning, enrichment and comparison. Each stage reads explicit files and writes identifiable outputs. This implements the Monday lecture recommendations on project root paths, small files and clear interfaces; some stages intentionally produce more than one output.

### Reuse functions and expose parameters

The helpers in 2_scripts/0_tools/data_summary.R reuse the same monthly summary logic across fields. topPercent.R provides a reusable selection function, while build_req() and get_area_info() separate API request construction from response extraction. Script 7 exposes the layer, API key and file paths near the beginning. Script 11 defines file paths near the beginning, while its snapshot and quarter choices are written directly inside filter operations. Other choices, including the rental date window and histogram settings, remain visible in the relevant code and should be reviewed when the study period changes.

### Make expectations visible in the code

Descriptive names such as median_Airbnb_price, price_diff_per_night and count_difference explain the calculations. Scripts 7 and 11 explicitly read some identifier fields as character values. Script 7 stops if all codes in a newly generated lookup are missing. Most remaining checks are displayed values or calculated objects rather than executable assertions: script 8 calculates a check value without comparing it with the input row count, and script 11 prints area and count totals. These practices partly implement the Monday lecture guidance on self-documenting code and sanity checks.

### Inspect outputs and support reproduction

Monthly summaries, cleaning logs, histograms, str(), displayed result tables, missing SA2 counts and printed count totals provide checks during development. These support the lecture recommendations to inspect inputs, intermediate results and final outputs. They are diagnostic checks rather than a complete automated test suite. The project includes renv.lock and renv activation files to record package dependencies. Reproduction requires the original raw CSVs, a compatible R installation and restored packages; new geographic lookups also require API access. The current workflow runs scripts in dependency order, without an automatic build controller.

### Use AI with human review

AI used: OpenAI ChatGPT through the Codex coding agent. For this version, it reviewed the original supplied project and lecture slides and drafted this document, with identified problems recorded separately below. Following the Tuesday lecture on human-in-the-loop coding, the group remains responsible for the research aims, reviewing this description, running the pipeline with the original data and confirming that the resulting comparisons answer the intended questions.


## 5 Issues identified in the original project

The following findings concern the original code. They have not been implemented as changes. Some are definite inconsistencies; others depend on the actual source data or runtime and require verification.

### Output filename mismatch

Script 7 writes `airbnb_chch_cleaned_witharea.csv.` with a trailing period. Scripts 8 and 11 read `airbnb_chch_cleaned_witharea.csv` without it. The paths do not match in the code and can prevent downstream scripts from finding the generated file.

### Rental cleaning column names and log

Script 6 uses dotted column names such as `Geometric.Mean.Rent`, while its comments and the README describe space-separated names such as `Geometric Mean Rent`. `read_csv()` normally preserves spaces in headers. If the raw headers contain spaces, `any_of()` silently skips the dotted names, leaving the intended columns in place even though the log says they were removed. The raw headers need to be checked. The log also names `rental_bond_clean.csv`, whereas the script writes `tenancy_chch_cleaned.csv`.

### Dependence on session state

Scripts 4 and 10 call `here()` without loading `here` or using `here::here()`. They may work after another script loads the package, but can fail in a fresh session.

### Missing input files and output directory

The uploaded archive does not contain the Airbnb raw CSV folder, the rental CSV referenced by script 2, or a `3_output` directory. The scripts do not create that directory before writing files. The original data and directory must be supplied before execution. Script 1 also has no explicit check for an empty input file list.

### API test before cache reuse

The original `api_key` parameter is empty. Script 7 performs its test request before checking whether the lookup file exists, so a cache does not eliminate the initial requirement for API access. The test uses the first listing before checking that the input has rows or that its coordinates are available. The first coordinate can also be queried again in the subsequent bulk requests.

### Lookup coverage response parsing and duplicate keys

Script 7 does not verify that an existing cache covers the current coordinates or uses the same layer. Missing cache coverage leaves listings unmatched. Its response parser assumes that matching SA2 code and name fields exist; missing fields or an unexpected response structure can cause an error rather than a missing result.

The generated lookup uses distinct coordinate keys, but a reused cache is not checked for duplicate keys. Such duplicates could multiply listing rows during the left join.

### Identifier and join types

Earlier Airbnb stages infer identifier types even though scripts 7 and 11 later read IDs as text. Very large IDs can lose precision if initially parsed as floating-point numbers, and a later conversion to text cannot recover the original digits. Whether this occurs depends on the actual IDs.

Script 8 infers the types of `SA22026_code` and `Location Id`. Numeric-looking codes can receive compatible types, but mixed values can produce incompatible join types. No actual type conflict was confirmed without the source CSVs.

### Date and snapshot selection

Script 2 assumes an inferred `TimeFrame` type compatible with Date bounds. Script 11 compares it with `"2026/04/01"`. This is a conditional concern: a Date column can support the slash-formatted comparison, whereas a character column containing `"2026-04-01"` would not match that string. The type and selected rows need inspection.

Airbnb `year_month` depends on filenames containing `YYYY_MM`. Incorrect patterns produce missing snapshot labels. The selected rental dates and June Airbnb subset are not checked for non-empty results.

### Pooled counts and the incomplete count check

Script 8's `Number_of_Airbnb_properties` counts rows across snapshots rather than distinct listing IDs. A listing present in several snapshots can therefore contribute several observations. The field name can misrepresent that quantity. For a missing SA2 group, `table(SA22026_code)[1]` does not correctly count rows because `table()` excludes missing values by default.

The `check` object is only a sum; the script does not compare it with `nrow(airbnb_full)` or stop when they disagree.

### Price aggregation and missing values

Script 8 pools Airbnb snapshots and summarises rental quarters rather than matching individual periods. Its rental median is a median of quarterly medians, not a median of individual tenancy rents. Its maximum `Total Bonds` is neither a sum across quarters nor a current `Active Bonds` count. The summary calculations omit `na.rm = TRUE`, so missing rental values can make a location summary missing.

All retained Airbnb room types contribute to the price median, while rental rows use aggregate dwelling and bedroom categories. Dividing weekly rent by seven aligns the time unit but does not align accommodation type, size, fees or rental terms. The absolute price difference removes its direction. The results therefore require a descriptive interpretation rather than a profitability interpretation.

### Price filtering also affects property counts

Script 11 uses the cleaned Airbnb data, so listings with missing prices have already been excluded even though a price is not needed to count an ID. Its count is consequently a count of retained listings rather than necessarily all June listings. `Active Bonds` is a bond measure and has not been independently verified here as an exact count of all long-term rental homes.

### Missing counts converted to zero

Script 11 replaces both absent-source counts and missing values in existing source rows with zero. Missing or unavailable information does not establish a true count of zero. The output does not distinguish those situations, which can affect the count difference and printed totals.

### Count and area-name join assumptions

Script 11 assumes one `ALL`/`ALL` rental record per SA2 for the selected quarter without checking it. Duplicate records could multiply joined counts. Its area names come from Airbnb coordinate lookups rather than the complete Christchurch area table, so rental-only areas can have missing names. Distinct code and name pairs also do not guarantee a unique code if more than one name is associated with it. These risks need to be checked against the data.

### Christchurch Central extraction

Script 9 uses `SA22026_name == "Christchurch Central"` as a row index. Missing names produce missing logical indices, which can introduce missing elements into the selected vector. Taking its first element can then return a missing value even when a matching area exists. The script does not check that the intended area was found exactly once.

### Comments and cleaning claims

Script 11's first comment says it compares beds, but it calculates distinct listing counts and active rental bond counts. It does not calculate bed or bedroom totals.

Script 5 states that `license` is entirely missing without asserting that condition. Its `any_of()` selection also permits named columns to be absent while the log describes them as removed. Those cleaning claims need confirmation from the source data.

### Interpretation of exploratory plots and review summaries

The histograms and top 10 percent selection use combined snapshot observations, so listings can contribute more than once. The price histograms compare raw counts; the New Zealand group includes Christchurch and can have a different sample size. These are not independent or size-normalised comparisons. The fixed review reference date applies to all snapshots; reviews after that date, if present, produce negative elapsed days.

### Reproducibility and verification limits

The supplied `renv.lock` records R version `4.6.1`; dependency restoration and runtime compatibility were not tested. The project's `.gitignore` excludes `*.csv` and `*.csv.gz`, so newly added raw and lookup CSVs are not automatically tracked unless explicitly included. These patterns do not stop tracking files already committed. The source data and restoration instructions must remain available for reproduction.

There is no automated build controller, and executable checks for schema, date coverage, join uniqueness and expected row counts are limited. The original source CSVs are absent and R is unavailable in the review environment. These findings are based on code inspection, not a complete pipeline run; no numerical results or successful end-to-end execution are claimed.
