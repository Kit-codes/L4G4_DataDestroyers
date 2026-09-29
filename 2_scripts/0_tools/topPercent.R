# Returns rows where the vlaue in the reference columnn falls in the top (proportion) of values in that column
# data = data set
# refColumn = Variable of interest (column name)
# proportion = percentage represented as a proprtion (0.0 - 1.0)

library(tidyverse)

topPercent <- function (data, refColumn, proportion){
  data |>
     slice_max(
        order_by = refColumn,
        prop = proportion,
        with_ties = FALSE
        )

}





