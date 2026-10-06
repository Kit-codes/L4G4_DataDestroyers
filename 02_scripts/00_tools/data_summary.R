
# function to produce count only summary for a data set variable
count_only_summary <- function(dataset, column) {
  dataset |>
    group_by(year_month) |>
    summarise(
      count = sum(!is.na({{ column }})),
      unique_count = n_distinct({{ column }}, na.rm = TRUE),
      missing = sum(is.na({{ column }})),
      .groups = "drop"
    )
}


# function to count by category 
categories_summary <- function(dataset, column) {
  dataset |>
    group_by(year_month) |>
    count(
      {{column}}
    )
}

# min, max, mean, std
numeric_summary <- function(dataset, column) {
  dataset |>
    group_by(year_month) |>
    summarise(
      min = if (all(is.na({{ column }}))) NA_real_
      else min({{ column }}, na.rm = TRUE),
      max = if (all(is.na({{ column }}))) NA_real_
      else max({{ column }}, na.rm = TRUE),
      mean = if (all(is.na({{ column }}))) NA_real_
      else mean({{ column }}, na.rm = TRUE),
      std = if (all(is.na({{ column }}))) NA_real_
      else sd({{ column }}, na.rm = TRUE),
      missing = sum(is.na({{ column }})),
      .groups = "drop"
    )
}