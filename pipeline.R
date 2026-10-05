# ------------------------------------------------------------------------------
# Run the whole project
library(here)
# ------------------------------------------------------------------------------
# Run all scripts in number order
scripts <- list.files(here("2_scripts"), pattern = "^[0-9]+_.*\\.R$", full.names = TRUE)
scripts <- scripts[order(as.integer(sub("^([0-9]+)_.*", "\\1", basename(scripts))))]
# ------------------------------------------------------------------------------
# Deal with empty scripts 
empty <- scripts[file.size(scripts) == 0]
if (length(empty) > 0) {
  stop("Empty script(s): ", paste(basename(empty), collapse = ", "))
}

# collects all plots
pdf(here("3_output", "airbnb_plots.pdf"), width = 9, height = 6)
#
tryCatch({
  for (script in scripts) {
    cat("\n=====", basename(script), "=====\n")
    source(script, local = new.env(), print.eval = TRUE)
  }
}, finally = dev.off())

cat("\nDone. Plots: 3_output/airbnb_plots.pdf\n")