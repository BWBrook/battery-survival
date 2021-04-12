source("00_dependencies.R")

conf <- config::get()                              
battery_dat <- readr::read_csv(conf$in_dat)