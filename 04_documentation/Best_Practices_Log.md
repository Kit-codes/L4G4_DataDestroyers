# Coding Best Practices Log

#### **Planned Steps**

1.  Folder structure

2.  Create a naming convention 

3.  Rename current files

4.  Fix file pathing (fix read.csv issue/incosistency)

5.  Var names check consistency

6.  Sanity check (join checking)

#### **Completed Steps**

- Added new folders 1_data (renamed), 2_scripts, 3_output, 4_doccumentation, 5_renv (renamed)
- Moved folders/files into corresponding files
- Renamed deliverable scripts
- Delete unused or duplicate scripts
- Standardised on read_csv() rather than read.csv()
- Updated filepathing to reflect new folder structuring and using “here” package to force to root directory
- Changed some variable names to be more meaningful/give context
- Gave output files names that better reflected what they contained
- Split some scripts into separate scripts to make it easier to find things- specifically task related
- Brought in grouping by ward
- Updated readMe

#### **Naming conventions:**

**Folder**: ##\_name\
**Script:** ##\_(data it pertains to)\_(step/output) \
**Plots:** (script number that created the plot) \_(description) 

#### **Sanity Check examples:**

- Script 6 line 53 -  checks the output headers are what is expected and that the expected rows have been dropped
- Script 6 line 37 -  checks the output headers are what is expected and that the expected rows have been dropped
- Script 7 - #8 Checks - to make sure no listings have no area code
- Script 8 line 24-25  the sum of the number of airbnb properties in the summary data frame is compared to the number of rows in the full airbnb data set to make sure we have the same number of properties coming in and going out
- Check returns true if correct, false if not

*Note: additional sanity checks added during automation with error messaging and stops*

## **Code Quality Improvements**

Potential issues identified by AI (ChatGPT) during creation of Design Principles documentation

**Output filename mismatch:**

Script 7 writes airbnb_chch_cleaned_witharea.csv. with a trailing period. Scripts 8 and 11 read airbnb_chch_cleaned_witharea.csv without it. The paths do not match in the code and can prevent downstream scripts from finding the generated file.

- *Removed the trailing period*

**Rental cleaning column names and log**

Script 6 uses dotted column names such as Geometric.Mean.Rent, while its comments and the README describe space-separated names such as Geometric Mean Rent. read_csv() normally preserves spaces in headers. If the raw headers contain spaces, any_of() silently skips the dotted names, leaving the intended columns in place even though the log says they were removed. The raw headers need to be checked. The log also names rental_bond_clean.csv, whereas the script writes tenancy_chch_cleaned.csv.

- *Changed from dotted to spaced*
- *Corrected title of cleaning log*

**Dependence on session state**

Scripts 4 and 10 call here() without loading here or using here::here(). They may work after another script loads the package, but can fail in a fresh session.

- *Added library(here) to headers*

**Missing input files and output directory**

The uploaded archive does not contain the Airbnb raw CSV folder, the rental CSV referenced by script 2, or a 3_output directory. The scripts do not create that directory before writing files. The original data and directory must be supplied before execution. Script 1 also has no explicit check for an empty input file list.

- *REVIEW: no data  -  whether data should be uploaded to Github is controversial. . Resolved: data uploaded to git (compressed for space)*
- *no output folder in directory - as designed, resolved by adding code to automatically create folder structure if it doesn't exist to pipeline*

**API test before cache reuse**

The original api_key parameter is empty. Script 7 performs its test request before checking whether the lookup file exists, so a cache does not eliminate the initial requirement for API access. The test uses the first listing before checking that the input has rows or that its coordinates are available. The first coordinate can also be queried again in the subsequent bulk requests.

- *This is as designed - API key not to be uploaded to git, must be added separately*
- *added instructions on how to get an api key to readme* 

**Lookup coverage response parsing and duplicate keys**

Script 7 does not verify that an existing cache covers the current coordinates or uses the same layer. Missing cache coverage leaves listings unmatched. Its response parser assumes that matching SA2 code and name fields exist; missing fields or an unexpected response structure can cause an error rather than a missing result.

The generated lookup uses distinct coordinate keys, but a reused cache is not checked for duplicate keys. Such duplicates could multiply listing rows during the left join.

- *REVIEW: check if this needs addressing. Resolved: this is beyond scope*

**Identifier and join types**

Earlier Airbnb stages infer identifier types even though scripts 7 and 11 later read IDs as text. Very large IDs can lose precision if initially parsed as floating-point numbers, and a later conversion to text cannot recover the original digits. Whether this occurs depends on the actual IDs.

Script 8 infers the types of SA22026_code and Location Id. Numeric-looking codes can receive compatible types, but mixed values can produce incompatible join types. No actual type conflict was confirmed without the source CSVs.

- *REVIEW: double check, but don't think this is an issue using read_CSV. Resolved: Left as is, no issues.*

**Date and snapshot selection**

Script 2 assumes an inferred TimeFrame type compatible with Date bounds. Script 11 compares it with "2026/04/01". This is a conditional concern: a Date column can support the slash-formatted comparison, whereas a character column containing "2026-04-01" would not match that string. The type and selected rows need inspection.

Airbnb year_month depends on filenames containing YYYY_MM. Incorrect patterns produce missing snapshot labels. The selected rental dates and June Airbnb subset are not checked for non-empty results.

- *Changed script 11 to be consistent with other dates,*
- *Review: have a closer look at the date formatting and if there is any major issue here. Resolved: change to how this is done*

**Pooled counts and the incomplete count check**

Script 8's Number_of_Airbnb_properties counts rows across snapshots rather than distinct listing IDs. A listing present in several snapshots can therefore contribute several observations. The field name can misrepresent that quantity. For a missing SA2 group, table(SA22026_code)[1] does not correctly count rows because table() excludes missing values by default.

- *OK - its a sum of the number of properties in each area code, not a count of unique area codes - it counts the number of times that area code appears in the original table* 

The check object is only a sum; the script does not compare it with nrow(airbnb_full) or stop when they disagree.

- *Fixed*

**Price aggregation and missing values**

Script 8 pools Airbnb snapshots and summarises rental quarters rather than matching individual periods. Its rental median is a median of quarterly medians, not a median of individual tenancy rents. Its maximum Total Bonds is neither a sum across quarters nor a current Active Bonds count. The summary calculations omit na.rm = TRUE, so missing rental values can make a location summary missing.

-  *REVIEW: ALL, ALL rows are a summary, this is clarified in the comments but may remain unclear.*

All retained Airbnb room types contribute to the price median, while rental rows use aggregate dwelling and bedroom categories. Dividing weekly rent by seven aligns the time unit but does not align accommodation type, size, fees or rental terms. The absolute price difference removes its direction. The results therefore require a descriptive interpretation rather than a profitability interpretation.

- *yes , thats all the data we have* 

**Price filtering also affects property counts**

Script 11 uses the cleaned Airbnb data, so listings with missing prices have already been excluded even though a price is not needed to count an ID. Its count is consequently a count of retained listings rather than necessarily all June listings. Active Bonds is a bond measure and has not been independently verified here as an exact count of all long-term rental homes.

- *This probably isnt correct - review and maybe keep price na rows, or create a secondary set* 

 **Missing counts converted to zero**

Script 11 replaces both absent-source counts and missing values in existing source rows with zero. Missing or unavailable information does not establish a true count of zero. The output does not distinguish those situations, which can affect the count difference and printed totals.

- *REVIEW: working ok, so need to confirm not an issue. Resolved: tested and ok*

 **Count and area-name join assumptions**

Script 11 assumes one ALL/ALL rental record per SA2 for the selected quarter without checking it. Duplicate records could multiply joined counts. Its area names come from Airbnb coordinate lookups rather than the complete Christchurch area table, so rental-only areas can have missing names. Distinct code and name pairs also do not guarantee a unique code if more than one name is associated with it. These risks need to be checked against the data.

- *Checked. Ok*

**Christchurch Central extraction**

Script 9 uses SA22026_name == "Christchurch Central" as a row index. Missing names produce missing logical indices, which can introduce missing elements into the selected vector. Taking its first element can then return a missing value even when a matching area exists. The script does not check that the intended area was found exactly once.

-  *there might be a cleaner way to do it, but the result is correct.*

**Comments and cleaning claims**

Script 11's first comment says it compares beds, but it calculates distinct listing counts and active rental bond counts. It does not calculate bed or bedroom totals.

- *REVIEW: works, is ok.*

Script 5 states that license is entirely missing without asserting that condition. Its any_of() selection also permits named columns to be absent while the log describes them as removed. Those cleaning claims need confirmation from the source data

- *This is fine, its known that there are no licenses. Could maybe add a check, but seems redundant since we also don't care about licensing*
- *Added some extra context in the cleaning log to state its not needed*

 **Interpretation of exploratory plots and review summaries**

The histograms and top 10 percent selection use combined snapshot observations, so listings can contribute more than once. The price histograms compare raw counts; the New Zealand group includes Christchurch and can have a different sample size. These are not independent or size-normalised comparisons. The fixed review reference date applies to all snapshots; reviews after that date, if present, produce negative elapsed days.

- *REVIEW: seems ok.*

**Reproducibility and verification limits**

The supplied renv.lock records R version 4.6.1; dependency restoration and runtime compatibility were not tested. The project's .gitignore excludes \*.csv and \*.csv.gz, so newly added raw and lookup CSVs are not automatically tracked unless explicitly included. These patterns do not stop tracking files already committed. The source data and restoration instructions must remain available for reproduction.

- *As designed - outputs not to be added to Git and are produced when pipeline is first . Changes made to lock file to include raw data folder*

There is no automated build controller, and executable checks for schema, date coverage, join uniqueness and expected row counts are limited. The original source CSVs are absent and R is unavailable in the review environment. These findings are based on code inspection, not a complete pipeline run; no numerical results or successful end-to-end execution are claimed.

- *Added in future deliverable*
