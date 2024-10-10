library(tidyverse); library(devtools);

# Create R package data directory ----
dir.create('../data')

# Store release number and date ----
data_release_date <- as.Date("2024-04-01")
data_release_version <- 5
NA_STRINGS <- c('-9999', '-8888', 'NULL', 'NaT')
usethis::use_data(data_release_date, overwrite = TRUE)
usethis::use_data(data_release_version, overwrite = TRUE)

# Read and store xlsx files ----
xlsx_files <- list.files(".", pattern = "\\.xlsx$", full.names = TRUE, recursive = TRUE)
for (file_name in xlsx_files) {
  df_name <- basename(file_name) %>%
    gsub(pattern = "\\.xlsx$", replacement = "") %>%
    gsub(pattern = paste0(' Release ', data_release_version), replacement = '') %>%
    gsub(pattern = ' ', replacement = '_')
  df <- readxl::read_excel(file_name)
  assign(df_name, df)
  # using defaults from usethis::use_data
  save(list = df_name, file = file.path("..", "data", paste0(df_name, ".rda")),
    compress = "bzip2", version = 2)
}

# Define coding functions to parse dictionary ----

get_levels <- function(x){
  as.numeric(unlist(lapply(strsplit(unlist(strsplit(subset(
    HD_Data_Dictionary, `Main Variable`==x)$`Value/File name`, '}{',
    fixed = TRUE)), ', '), function(y) gsub('{', '', y[1], fixed = TRUE))))
}

get_labels <- function(x){
  unlist(lapply(strsplit(unlist(strsplit(subset(
    HD_Data_Dictionary, `Main Variable`==x)$`Value/File name`, '}{',
    fixed = TRUE)), ', '), function(y) gsub('}', '', y[2], fixed = TRUE)))
}

# subset(HD_Data_Dictionary, `Main Variable`=="Interview_Site")$`Value/File name`
# get_levels("Interview_Site")
# get_labels("Interview_Site")

# Read and store csv files ----
csv_files <- list.files(".", pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)
for (file_name in csv_files) {
  df_name <- basename(file_name) %>%
    gsub(pattern = "\\.csv$", replacement = "") %>%
    gsub(pattern = paste0(' Release ', data_release_version), replacement = '') %>%
    gsub(pattern = '_FINAL', replacement = '') %>%
    gsub(pattern = ' ', replacement = '_')
  message('Reading ', df_name)
  df <- read_csv(file_name, na = NA_STRINGS)
  for(cc in colnames(df)){
    dic.sub <- subset(HD_Data_Dictionary, `Main Variable`==cc)
    if(nrow(dic.sub)==1)
    if(grepl('{', dic.sub$`Value/File name`, fixed = TRUE))
    if(length(get_levels(cc)) == length(get_labels(cc)) & !any(is.na(get_levels(cc)))){
      message('Coding ', cc)
      # subset(HD_Data_Dictionary, `Main Variable`==cc)$`Value/File name`
      df[, cc] <- factor(df %>% pull(cc), 
            levels = get_levels(cc),
            labels = get_labels(cc))
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

usethis::use_data(HD_longitudinal, overwrite = TRUE)
usethis::use_data(HD_subjinfo, overwrite = TRUE)
usethis::use_data(HD_labels, overwrite = TRUE)
