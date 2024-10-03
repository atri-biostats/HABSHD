library(tidyverse)

dir.create(file.path("..", "R"))

# Add HABSHD-package.R file ----
cat("#' @keywords internal",
  "\"_PACKAGE\"\n",
  "## usethis namespace: start",
  "#' @importFrom rmarkdown pdf_document knitr_options_pdf",
  "## usethis namespace: end",
  "NULL",
  file = file.path('..', 'R', 'HABSHD-package.R'), sep = '\n')

# Document data dictionary and data_download_date ----
cat("#' HABSHD data dictionary",
  "#'",
  "#' These data files contain meta data for other data files in this package.",
  "#'",
  "#' @docType data",
  "#' @name HD_Data_Dictionary_Release_5",
  "#' @usage data(HD_Data_Dictionary_Release_5)",
  "#' @format A data frame",
  "#' @keywords datasets dictionary datadictionary",
  "#' @examples",
  "#' \\dontrun{",
  "#' browseVignettes('HABSHD')",
  "#' }",
  "NULL\n",
  "#' HABSHD data release date",
  "#'",
  "#' The date when data in this package were released.",
  "#'",
  "#' @docType data",
  "#' @keywords datasets",
  "#' @name data_release_date",
  "#' @usage data(data_release_date)",
  "#' @format A `Date` class object.",
  "#' @examples",
  "#' \\dontrun{",
  "#' browseVignettes('HABSHD')",
  "#' }",
  "NULL\n",
  "#' HABSHD data release version",
  "#'",
  "#' The version number of this data release.",
  "#'",
  "#' @docType data",
  "#' @keywords datasets",
  "#' @name data_release_version",
  "#' @usage data(data_release_version)",
  "#' @format A `numeric`.",
  "#' @examples",
  "#' \\dontrun{",
  "#' browseVignettes('HABSHD')",
  "#' }",
  "NULL\n\n",
  file = file.path("..", "R", "data.R"), sep = "\n")

# function for escaping braces ----
escape <- function(x){
  y <- gsub("{", "\\{", x, fixed = TRUE)
  gsub('\r', ' ', gsub('\n', ' ', gsub("}", "\\}", y, fixed = TRUE)))
}

# HD_Data_Dictionary_Release_5 %>%
#   filter(`Main Variable` == '01_TAU_PI2620_Scanner') %>%
#   pull(Label) %>% escape()

# get csv data info ----

csv_files <- list.files("../data-raw/", pattern = "\\.csv$", full.names = TRUE, recursive = TRUE)

# Document csv sourced dataset(s) ----
for(ff in csv_files){
  tt <- gsub(' ', '_', gsub("\\.csv$", "", basename(ff)))
  message('Documenting ', tt)
  assign("dd", get(tt))
  dic.sub <- subset(HD_Data_Dictionary_Release_5, `Main Variable` %in% 
      colnames(dd))
  cat(paste0("#' ", tt),
    "#' @description HABS-HD raw dataset.",
    "#' @details",
    "#' \\itemize{",
    paste("#'   \\item", paste0(
      dic.sub$`Main Variable`, ": ",
      escape(dic.sub$Label), '. Units: ',
      dic.sub$`Missing/Unit of Measure`, '. Coding: ',
      escape(dic.sub$`Value/File name`))),
    "#' }",
    "#' @docType data",
    "#' @keywords datasets",
    paste("#' @name", tt),
    paste0("#' @usage data(", tt, ")"),
    paste("#' @format A data frame with", nrow(dd), "rows and", ncol(dd), "variables."),
    "#' @examples",
    "#' \\dontrun{",
    "#' browseVignettes('HABSHD')",
    "#' }",
    "NULL\n", sep = "\n",
    file = file.path("..", "R", "data.R"), append = TRUE)          
}

# Add static documents ----
doc_files <- list.files(file.path('..', 'data-raw'), 
  pattern = "\\.pdf$", full.names = TRUE, recursive = TRUE)
for (file_name in doc_files) {
  doc_name <- gsub("\\.pdf$", "", basename(file_name))
  file.copy(file_name, file.path('..', 'vignettes', 
    paste0(doc_name,'_original.pdf')))
  cat("\\documentclass{article}",
    "\\usepackage{pdfpages}",
    paste0("%\\VignetteIndexEntry{", doc_name, "}"),
    "\\begin{document}",
    paste0("\\includepdf[pages=-, fitpaper=true]{", paste0(doc_name,'_original.pdf'), "}"),
    "\\end{document}", 
    file = file.path('..', 'vignettes', paste0(doc_name, '.Rnw')),
    sep = '\n')
}

