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
    gsub('04_', '', .) %>%
    gsub('r5_LUM_Plasma_SARS_CoV2_Spike_B_', 
      'r5LUMPlasmaSARSCoV2SpikeB', .) %>%
    gsub('_Anterior', 'Ant', .) %>%
    gsub('_Posterior', 'Post', .) %>%
    gsub('_Superior', 'Sup', .) %>%
    gsub('_Inferior', 'Inf', .) %>%
    gsub('_limb_of', 'Limb', .) %>%
    gsub('_internal', 'Int', .) %>%
    gsub('_capsule', 'Cap', .) %>%
    gsub('_thalamic', 'Thal', .) %>%
    gsub('_radiation', 'Rad', .) %>%
    gsub('_longitudinal', 'Long', .) %>%
    gsub('_fasciculus', 'Fasc', .) %>%
    gsub('_occipital', 'Occ', .) %>%
    gsub('_fronto', 'Front', .) %>%
    gsub('_of_corpus_callosum', 'CorpCall', .) %>%
    substr(., 1, 32)
  if(any(duplicated(y))){
    stop('Duplicate variable names:', y[duplicated(y)])
  }
  # y <- make.unique(y)
  if(any(y != x)){
    warning('Variable names converted for SAS')
    converted_names <- data.frame(old_name = x[y != x], new_name = y[y != x])
    print(converted_names)
  }else{
    converted_names <- NULL
  }
  list(all_names = y, converted_names = converted_names)
}

CN <- NULL
for(ff in setdiff(c(rda_names, 'HD_meta_data'), 'HD_Data_Dictionary')){
  dd <- get(ff)
  tmp <- prep_names_for_sas(colnames(dd))
  colnames(dd) <- tmp$all_names
  CN <- bind_cols(table = ff, tmp$converted_names) %>%
    bind_rows(CN)
  write_xpt(dd, paste0(ff, '.xpt'))
}

# update and write SAS data dictionary ----
CN <- CN %>% 
  filter(!is.na(old_name)) %>%
  select(-table) %>%
  distinct()
if(any(duplicated(CN$old_name))){
  stop('Old names mapped to more than one new name:',
    CN$old_name[duplicated(CN$old_name)])
}

dd <- HD_Data_Dictionary
colnames(dd) <- prep_names_for_sas(colnames(dd))$all_names
dd <- dd %>%
  rename(old_name = Main_Variable) %>%
  left_join(CN, by='old_name') %>%
  mutate(
    Main_Variable = case_when(
      !is.na(new_name) ~ new_name,
      TRUE ~ old_name)) %>%
  rename(Original_Main_Variable = old_name) %>%
  select(Category, Original_Main_Variable, Main_Variable,
    everything())
write_xpt(dd, 'HD_Data_Dictionary.xpt')
