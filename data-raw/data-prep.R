library(tidyverse); library(devtools);

# Create R package data directory ----
dir.create(file.path('..', 'data'))
file.remove(file.path('..', 'data', list.files('../data')))

# Store release number and date ----
data_release_date <- as.Date("2024-12-06")
data_release_major_version <- "6"
data_release_version <- "6.1"
NA_STRINGS <- c('-9999', '-8888', '-777777', 'NULL', 'NaT')
usethis::use_data(data_release_date, overwrite = TRUE)
usethis::use_data(data_release_version, overwrite = TRUE)

# Read and store xlsx files ----
xlsx_files <- list.files(paste("Release", data_release_version), pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)
for (file_name in xlsx_files) {
  df_name <- basename(file_name) %>%
    gsub(pattern = "\\.xlsx$", replacement = "") %>%
    gsub(pattern = paste(' Release', data_release_major_version), replacement = '') %>%
    gsub(pattern = ' ', replacement = '_')
  df <- readxl::read_excel(file_name)
  assign(df_name, df)
  # using defaults from usethis::use_data
  save(list = df_name, file = file.path("..", "data", paste0(df_name, ".rda")),
    compress = "bzip2", version = 2)
}

# Row bind data dictionaries ----
HD_Data_Dictionary <- bind_rows(
  HD_Data_Dictionary_Biomarker_Release,
  HD_Data_Dictionary_Clinical_Release,
  HD_Data_Dictionary_Genomics_Release %>%
    mutate(
      `Missing/Unit of Measure` = as.character(`Missing/Unit of Measure`),
      `Visits` = as.character(`Visits`)),
  HD_Data_Dictionary_Imaging_Release
)

save(HD_Data_Dictionary, file = file.path("..", "data", "HD_Data_Dictionary.rda"),
  compress = "bzip2", version = 2)
dictionaries <- c('HD_Data_Dictionary_Biomarker_Release',
  'HD_Data_Dictionary_Clinical_Release',
  'HD_Data_Dictionary_Genomics_Release',
  'HD_Data_Dictionary_Imaging_Release')
rm(list = dictionaries)
file.remove(file.path('..', 'data', paste0(dictionaries, '.rda')))

# Define coding functions to parse dictionary ----

HD_Data_Dictionary$Value <- gsub("9.00,Undetermined", "9.00, Undetermined",
  HD_Data_Dictionary$Value) 

get_levels <- function(x){
  as.numeric(unlist(lapply(strsplit(unlist(strsplit(subset(
    HD_Data_Dictionary, `Main Variable`==x)$`Value`, '}{',
    fixed = TRUE)), ', '), function(y) gsub('{', '', y[1], fixed = TRUE))))
}

get_labels <- function(x){
  unlist(lapply(strsplit(unlist(strsplit(subset(
    HD_Data_Dictionary, `Main Variable`==x)$`Value`, '}{',
    fixed = TRUE)), ', '), function(y) gsub('}', '', y[2], fixed = TRUE)))
}

# subset(HD_Data_Dictionary, `Main Variable`=="Interview_Site")$`Value`
# get_levels("Interview_Site")
# get_labels("Interview_Site")

# Read and store csv files ----
csv_files <- list.files(paste("Release", data_release_version), pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
for (file_name in csv_files) {
  df_name <- basename(file_name) %>%
    gsub(pattern = "\\.csv$", replacement = "") %>%
    gsub(pattern = paste0(' Release ', data_release_major_version), replacement = '') %>%
    gsub(pattern = '_FINAL', replacement = '') %>%
    gsub(pattern = ' ', replacement = '_')
  message('Reading ', df_name)
  df <- read_csv(file_name, na = NA_STRINGS)
  for(cc in colnames(df)){
    dic.sub <- subset(HD_Data_Dictionary, `Main Variable`==cc)
    if(nrow(dic.sub)==1){
      if(grepl('{', dic.sub$`Value`, fixed = TRUE)){
        if(length(get_levels(cc)) == length(get_labels(cc)) & !any(is.na(get_levels(cc)))){
          message('Coding ', cc)
          # subset(HD_Data_Dictionary, `Main Variable`==cc)$`Value`
          df[, cc] <- factor(df %>% pull(cc), 
            levels = get_levels(cc),
            labels = get_labels(cc))}
        if(length(get_levels(cc))>0 & any(is.na(get_levels(cc))))
          message(paste(df_name, cc, "levels:", get_levels(cc)))
      }
    }
  }
  assign(df_name, df)
  # using defaults from usethis::use_data
  save(list = df_name, file = file.path("..", "data", paste0(df_name, ".rda")),
    compress = "bzip2", version = 2)
}

# Derived data ----
knitr::purl('../vignettes/HABS-HD-Derived-Data.Rmd',
  'HABS-HD-Derived-Data.R')

source('HABS-HD-Derived-Data.R')

usethis::use_data(HD_Biomarkers, overwrite = TRUE)
usethis::use_data(HD_Clinical, overwrite = TRUE)
usethis::use_data(HD_Genomics, overwrite = TRUE)
usethis::use_data(HD_Imaging, overwrite = TRUE)
usethis::use_data(HD_subjinfo, overwrite = TRUE)
usethis::use_data(HD_labels, overwrite = TRUE)
