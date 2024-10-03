# Building HABSHD from csv files <a href="https://apps.unthsc.edu/itr/research/"><img src="../man/figures/logo.png" align="right" height="138" /></a>

To generate the package from source csv files:

- clone this repository
- download HABS-HD data from <https://apps.unthsc.edu/itr/research/> and
  copy all directories to [data-raw](data-raw)
- `source('data-raw/data-prep.R', chdir=TRUE)` to convert
  `data-raw/*.csv` files to `data/*.rda` files
- `source('tools/build.R', chdir=TRUE)` to generate documentation and
  build R package
