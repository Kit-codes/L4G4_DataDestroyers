# Christchurch Listings - Cleaning Log

## Dataset summary

- Rows in input dataset: **28795**
- Rows in cleaned dataset: **18128**

## Columns removed

- `license`: all values were missing.
- `neighbourhood_group`: constant after Christchurch filtering.
- `name`: listing title not required for the planned analysis.
- `host_name`: not required for the planned analysis.

## Rows removed

- Missing `price`: **10667** rows
  (37%).

`price` is required for the planned comparison with rental bond data.
Missing prices were not imputed because this would create values that
were not observed in the original listings.
