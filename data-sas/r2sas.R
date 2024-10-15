library(tidyverse); library(devtools);
library(haven) # includes write_xpt

# load HABS-HD R data ----
devtools::load_all('../')

# obtain all data.frame names ----
rda_names <- list.files("../data", pattern = "\\.rda$", 
  full.names = FALSE, recursive = TRUE) %>%
  gsub(pattern = "\\.rda$", replacement = "") %>%
  setdiff(c("data_release_version", "data_release_date"))

# convert non data.frame objects to data.frames ----
# write_xpt only works for data.frame objects

HD_labels <- tibble(
  Variable_name = names(HD_labels),
  Variable_label = HD_labels
)

HD_meta_data <- tibble(
  Meta_data = c("data_release_version", "data_release_date"),
  Meta_data_value = c(data_release_version, as.character(data_release_date))
)

for(ff in c(rda_names, 'HD_meta_data')){
  dd <- get(ff)
  colnames(dd) <- colnames(dd) %>%
    gsub(' ', '_', .) %>%
    gsub('/', '_', .)
  write_xpt(dd, paste0(ff, '.xpt'))
}
