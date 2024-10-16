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

manual_abbr <- c(
  IDRaceSpecifyOtherPacificRace = "ID_Race_Specify_OtherPacific_Race",
  IAC_Alternative1_Relationship_OtherRelative)

prep_names_for_sas <- function(x){
  y <- x %>%
    gsub(' ', '_', .) %>%
    gsub('/', '_', .) %>%
    gsub('-', '_', .) %>%
    gsub('.', '_', ., fixed = TRUE) %>%
    gsub("(", '', ., fixed = TRUE) %>%
    gsub(")", '', ., fixed = TRUE) %>%
    gsub('ó', 'o', .) %>%
    gsub('é', 'e', .) %>%
    gsub('í', 'i', .) %>%
    gsub('á', 'a', .) %>%
    gsub('01_', '', .) %>%
    gsub('02_', '', .) %>%
    gsub('03_', '', .) %>%
    gsub('r5_LUM_Plasma_SARS_CoV2_Spike_B_', 
      'r5LUMPlasmaSARSCoV2SpikeB', .) %>%
    gsub('AD_Anterior_limb_of_internal_capsule',
      'ADAnteLimbOfIntCap', .) %>%
    gsub('AD_Posterior_limb_of_internal_capsule',
      'ADPostLimbOfIntCap', .) %>%
    gsub('AD_Posterior_thalamic_radiation_',
      'ADPostThalRad', .) %>%
    gsub('AD_Superior_longitudinal_fascicu',
      'ADSupLongFasc', .) %>%
    substr(., 1, 32)
  y <- make.unique(y)
  if(any(y != x)){
    warning('Variable names converted for SAS')
    print(data.frame(old_name = x[y != x], new_name = y[y != x]))
  }
  y
}

for(ff in c(rda_names, 'HD_meta_data')){
  dd <- get(ff)
  colnames(dd) <- prep_names_for_sas(colnames(dd))
  write_xpt(dd, paste0(ff, '.xpt'))
}
