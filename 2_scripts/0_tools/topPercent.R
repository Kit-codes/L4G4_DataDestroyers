# Returns rows where the value in the reference column falls in the top (proportion) of values in that column
# data       = data set
# refColumn  = variable of interest (bare column name, e.g. number_of_reviews)
# proportion = percentage represented as a proportion (0.0 - 1.0)

library(tidyverse)

topPercent <- function(data, refColumn, proportion) {
  data |>
    slice_max(
      order_by = {{ refColumn }},
      prop = proportion,
      with_ties = FALSE
    )
}